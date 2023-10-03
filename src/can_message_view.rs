use std::borrow::BorrowMut;

use egui::{
    Color32, FontFamily, InnerResponse, Label, Response, RichText, TextEdit, TextStyle, Ui,
};

use crate::parser::CanMessage;

pub fn can_message(ui: &mut egui::Ui, can_message: &CanMessage) {
    // ui.add_sized(max_size, 
    ui.horizontal(|ui| {
        // ui.label(format!("{})", can_message.message_number));

        ui.add_sized(
            &[50.0, 20.0],
            // ui.label(format!("{})", can_message.message_number)),
            Label::new(format!("{})", can_message.message_number)),
        );
        // ui.text_edit_singleline(&mut "Test");
        // ui.add(
        //     TextEdit::singleline(&mut "Immutable &str\nSecond line")
        //         .min_size([0.0, 0.0].into())
        //         .desired_rows(1),
        // );
        // let text = can_message
        //     .data
        //     .iter()
        //     .map(|e| format!("{:02X}", e))
        //     .collect::<Vec<String>>()
        //     .join(" ");
        ui.add_space(15.0);

        ui.label(format!("0x{:X}", can_message.rx_id));
        ui.add_space(15.0);
        // if let Some(style) = self.style {
        //     *ui.style_mut() = style.clone();
        // }

        // ui.style().
        // ui.style_mut().visuals.panel_fill = Color32::BLUE;

        let mut result: Vec<(Color32, String)> = vec![];
        // let mut result: Vec<(Color32, String)> = can_message
        //     .data
        //     .iter()
        //     .map(|byte| (Color32::WHITE, format!("{:02X}", byte)))
        //     .collect();

        // // if (message.parent != null && message.parent! - message.messageNumber == -1) {

        // if can_message
        //     .parent
        //     .map(|parent| parent as i32 - can_message.message_number as i32)
        //     == Some(-1)
        // {
        //     result = result
        //         .into_iter()
        //         .map(|(_, byte)| (Color32::GRAY, byte))
        //         .collect();
        // } else if can_message.parent.is_none() {
        //     result[0] = (Color32::GRAY, result[0].1.clone());
        // }

        // if !can_message.multiline && can_message.parent.is_none() {
        //     let mut found_data = false;

        //     //             for i in can_message.data.len()..0 {
        //     // // if !found_data &&
        //     //             }

        //     result = result
        //         .iter()
        //         .rev()
        //         .map(|(color, byte)| {
        //             dbg!(byte);
        //             if !found_data && byte != "00" {
        //                 found_data = true;
        //             }

        //             if found_data {
        //                 (Color32::WHITE, byte.clone())
        //             } else {
        //                 (Color32::GRAY, byte.clone())
        //             }
        //         })
        //         // .rev()
        //         .collect::<Vec<(Color32, String)>>()
        //         .into_iter()
        //         .rev()
        //         .collect::<Vec<(Color32, String)>>();
        // }

        let mut found_data = false;

        for (i, byte) in can_message.data.iter().enumerate().rev() {
            // for i in (0..can_message.data.len()).rev() {
            // let byte = can_message.data[can_message.data.len() - i];

            if i == 0 && (can_message.parent.is_some() || can_message.multiline) {
                result.push((Color32::GRAY, format!("{:02X}", byte)));
            // }
            // else if *byte != 0 && can_message.parent.is_none() && !found_data {
            //     found_data = true;
            } else if can_message.parent.is_none() {
                if *byte != 0 {
                    found_data = true;
                }

                if !found_data {
                    result.push((Color32::GRAY, format!("{:02X}", byte)));
                } else {
                    result.push((Color32::WHITE, format!("{:02X}", byte)));
                }

                // dbg!(byte);
            } else {
                result.push((Color32::WHITE, format!("{:02X}", byte)));
            }
        }

        for (color, text) in result.into_iter().rev() {
            ui.colored_label(color, RichText::new(text).monospace());
        }
    });

    // ui.label(format!("0x{:X}", can_message.rx_id));
}
