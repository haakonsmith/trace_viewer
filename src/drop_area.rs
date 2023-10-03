use std::{fmt::UpperHex, fs, path::PathBuf};

use floem::{
    event::Event,
    peniko::Color,
    reactive::create_signal,
    unit::UnitExt,
    view::View,
    views::{
        container, dyn_container, label, scroll, stack, virtual_list, Decorators,
        VirtualListDirection, VirtualListItemSize,
    },
};

use crate::parser::{parse, CanMessage};

fn can_message_view(message: CanMessage) -> impl View {
    stack((label(move || format!("{:X}", message.rx_id)),))
}

fn trace_view(path: PathBuf) -> impl View {
    // let long_list: im::Vector<i32> = (0..10000).collect();
    let file_data = fs::read_to_string(path).expect("Message");
    let messages = im::Vector::from(parse(&file_data));

    let (long_list, _set_long_list) = create_signal(messages);

    container(
        // label(|| "TEST").style(|s| {
        //     s.color(Color::REBECCA_PURPLE)
        //         .background(Color::REBECCA_PURPLE)
        //         .height_full()
        // }),
        scroll(
            virtual_list(
                VirtualListDirection::Vertical,
                VirtualListItemSize::Fixed(Box::new(|| 20.0)),
                move || long_list.get(),
                move |item| item.message_number,
                move |item| {
                    can_message_view(item)
                    // label(move || item.to_string()).style(|s| s.height(20.0).width(90.pct()))
                },
            )
            .style(|s| s.flex_col()),
        )
        .style(|s| s.size_full().background(Color::REBECCA_PURPLE)),
    )
    .style(|s| {
        s
            // .size_full()
            // .padding_vert(20.0)
            // .background(Color::REBECCA_PURPLE)
            .flex_col()
            .items_center()
    })
}

pub fn drop_area() -> impl View {
    let (active_file, set_active_file) = create_signal::<Option<PathBuf>>(None);

    dyn_container(
        move || active_file.get(),
        move |file| match file {
            Some(path) => Box::new(trace_view(path).style(|s| s.size_full())),
            None => Box::new(label(|| "Drop Here").style(|s| s.width(10))),
        },
    )
    .style(|s| s.size(100.pct(), 90.pct()).items_center().justify_center())
    .on_event(
        floem::event::EventListener::DroppedFile,
        move |event| match event {
            Event::DroppedFile(path) => {
                if path.is_file() {
                    set_active_file.update(|value| *value = Some(path.clone()))
                }

                true
            }
            _ => false,
        },
    )
}
