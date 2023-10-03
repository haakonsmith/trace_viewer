use std::str;

enum ParseError {}

#[derive(PartialEq, PartialOrd, Clone)]
pub struct CanMessage {
    pub rx_id: usize,
    pub multiline: bool,
    pub data: Vec<u8>,
    pub time_offset: f64,
    pub message_number: usize,
    pub parent: Option<usize>,
}

pub fn parse(data: &str) -> Vec<CanMessage> {
    let lines = data.lines().skip(14).collect::<Vec<&str>>();

    parse_lines(lines)
}

fn parse_line(line: &str) -> [&str; 6] {
    let mut start_index = 0;
    let mut found = false;
    let mut result: [&str; 6] = [" "; 6];
    let bytes = line.as_bytes();
    let mut index = 0;

    for i in 0..line.len() {
        let character = bytes[i];

        if character == b' ' {
            if found {
                result[index] = &line[start_index..i];
                index += 1;

                found = false;
            }

            continue;
        }

        if character != b' ' && !found {
            start_index = i;
            found = true;
        }

        if index == 5 {
            break;
        }
    }

    result[5] = &line[start_index..line.len()].trim();
    result[0] = &result[0][..result[0].len() - 1];

    result
}

fn parse_bytes(data: &str) -> Vec<u8> {
    data.split_ascii_whitespace()
        .map(|e| u8::from_str_radix(e, 16).unwrap())
        .collect::<Vec<u8>>()
}

fn parse_lines(lines: Vec<&str>) -> Vec<CanMessage> {
    let mut messages = Vec::<CanMessage>::with_capacity(lines.len());

    let mut multi_line_counter = None;
    let mut parent_index = None;

    for i in 0..lines.len() {
        let line = lines[i];
        let [message_number, time_offset, _, id, _data_length, data] = parse_line(line);

        let bytes = parse_bytes(data);

        let first_byte = bytes[0];
        let next_first_byte = {
            if i < (lines.len() - 1) {
                let [.., data] = parse_line(lines[i + 1]);

                u8::from_str_radix(data.split_ascii_whitespace().nth(0).unwrap(), 16).ok()
            } else {
                None
            }
        }
        .unwrap_or(0);

        if next_first_byte == 0x30 {
            multi_line_counter = Some(0);
            parent_index = Some(i);

            messages.push(CanMessage {
                rx_id: usize::from_str_radix(id, 16).expect("This should work"),
                multiline: true,
                data: bytes,
                time_offset: time_offset.parse::<f64>().expect("THIS SHOULD WORk"),
                message_number: message_number.parse::<usize>().expect("This should work"),
                parent: None,
            });
        } else if multi_line_counter == Some(0) && first_byte == 0x30 {
            multi_line_counter = Some(1);

            messages.push(CanMessage {
                rx_id: usize::from_str_radix(id, 16).expect("This should work"),
                multiline: false,
                data: bytes,
                time_offset: time_offset.parse::<f64>().expect("THIS SHOULD WORk"),
                message_number: message_number.parse::<usize>().expect("This should work"),
                parent: parent_index,
            });
        } else if Some(first_byte) == multi_line_counter.and_then(|e| Some(e + 0x20)) {
            messages.push(CanMessage {
                rx_id: usize::from_str_radix(id, 16).expect("This should work"),
                multiline: false,
                data: bytes,
                time_offset: time_offset.parse::<f64>().expect("THIS SHOULD WORk"),
                message_number: message_number.parse::<usize>().expect("This should work"),
                parent: parent_index,
            });

            if multi_line_counter == Some(0x10) {
                multi_line_counter = Some(0);
            }
        } else {
            multi_line_counter = None;

            messages.push(CanMessage {
                rx_id: usize::from_str_radix(id, 16).expect("This should work"),
                multiline: false,
                data: bytes,
                time_offset: time_offset.parse::<f64>().expect("THIS SHOULD WORk"),
                message_number: message_number.parse::<usize>().expect("This should work"),
                parent: parent_index,
            });
        }
    }

    messages
}
