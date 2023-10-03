#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")] // hide console window on Windows in release

use std::{
    borrow::BorrowMut,
    collections::BTreeMap,
    fmt::format,
    fs,
    ops::Add,
    path::PathBuf,
    string::ParseError,
    sync::mpsc,
    thread::{self, JoinHandle},
};

use can_message_view::can_message;
use eframe::egui::{self, Context};
use egui::{ahash::HashMap, collapsing_header::CollapsingState, Ui};
use egui_dock::{DockArea, DockState, Style};
use parser::{parse, CanMessage};

mod can_message_view;
mod parser;

fn main() -> Result<(), eframe::Error> {
    env_logger::init(); // Log to stderr (if you run with `RUST_LOG=debug`).
    let options = eframe::NativeOptions {
        initial_window_size: Some(egui::vec2(320.0, 240.0)),
        ..Default::default()
    };
    eframe::run_native(
        "My egui App",
        options,
        Box::new(|cc| Box::<TracerViewerApp>::default()),
    )
}

struct Buffer {
    data: Result<Vec<CanMessage>, ParseError>,
    visible: Vec<bool>,
    data_indicies: Vec<usize>,
    data_count: usize,
}

type BufferValue = Buffer;

struct Buffers {
    buffers: BTreeMap<String, BufferValue>,
}

impl egui_dock::TabViewer for Buffers {
    type Tab = String;

    fn title(&mut self, title: &mut String) -> egui::WidgetText {
        egui::WidgetText::from(&*title)
    }

    fn ui(&mut self, ui: &mut egui::Ui, title: &mut String) {
        let buffer = self.buffers.get_mut(title);

        if let Some(buffer) = buffer {
            match &buffer.data {
                Ok(data) => {
                    // let visible_data = buffer
                    //     .visible
                    //     .iter()
                    //     .enumerate()
                    //     .map(|(i, visible)| data[i]);
                    // let visible_data = data.iter().enumerate().collect().reta(|(i, data)| buffer.visible[i]);
                    // let mut drop = buffer.visible.iter();
                    // data.retain(|_| !drop.next().unwrap());
                    // let data.iter().filter(|_| *drop.next().unwrap());

                    egui::ScrollArea::vertical()
                        .auto_shrink([false; 2])
                        .show_rows(ui, 20.0, buffer.data_indicies.len(), |ui, row_range| {
                            // dbg!(&row_range);
                            for i in row_range {
                                if i >= buffer.data_indicies.len() {
                                    break;
                                }

                                let start_index = buffer.data_indicies[i];
                                let message = &data[start_index];

                                if message.multiline {
                                    // let id = ui.make_persistent_id(format!("id-{}", i));

                                    // CollapsingState::load_with_default_open(ui.ctx(), id, false)
                                    //     .show_header(ui, |ui| {
                                    //         can_message(ui, message);
                                    //         // ui.label("text");
                                    //     })
                                    //     .body(|ui| {
                                    //         // ui.label("text");
                                    //         let mut i = start_index + 1;
                                    //         while data[i].parent.is_some() {
                                    //             can_message(ui, &data[i]);
                                    //             i += 1;
                                    //         }
                                    //     });
                                    ui.horizontal(|ui| {
                                        if ui.button("Expand").clicked() {
                                            let mut j = start_index + 1;
                                            while data[j].parent.map(|parent| parent == start_index)
                                                == Some(true)
                                            {
                                                j += 1;
                                            }

                                            let visible = buffer.visible[start_index + 1];

                                            if visible {
                                                let data_length = start_index..j;
                                                buffer
                                                    .data_indicies
                                                    .drain(i + 1..data_length.len() + i);
                                                dbg!(&buffer.data_indicies[0..j + 10]);

                                                buffer.visible.splice(
                                                    start_index..j,
                                                    vec![false; j - start_index],
                                                );
                                            } else {
                                                buffer
                                                    .data_indicies
                                                    .splice(i..i + 1, start_index..j);

                                                buffer.visible.splice(
                                                    start_index..j,
                                                    vec![true; j - start_index],
                                                );
                                            }
                                        }

                                        can_message(ui, message);
                                    });
                                } else {
                                    can_message(ui, message);
                                }
                            }
                        });
                }
                Err(_) => {
                    ui.label("SOMETHING WENT WORNG!");
                }
            }
        } else {
            ui.label("Loading");
            ui.spinner();
        }
    }
}
struct TracerViewerApp {
    dropped_files: Vec<egui::DroppedFile>,
    picked_path: Option<String>,
    buffers: Buffers,
    tree: DockState<String>,
    threads: Vec<(Option<JoinHandle<()>>, String)>,
    on_done_tx: mpsc::SyncSender<BufferValue>,
    on_done_rc: mpsc::Receiver<BufferValue>,
}

impl Default for TracerViewerApp {
    fn default() -> Self {
        let tree = DockState::new(vec![]);
        let buffers = BTreeMap::<String, BufferValue>::default();
        let (on_done_tx, on_done_rc) = mpsc::sync_channel(0);

        Self {
            dropped_files: vec![],
            picked_path: None,
            tree,
            buffers: Buffers { buffers },
            on_done_rc,
            on_done_tx,
            threads: vec![],
        }
    }
}

fn preview_files_being_dropped(ctx: &egui::Context) {
    use egui::*;
    use std::fmt::Write as _;

    if !ctx.input(|i| i.raw.hovered_files.is_empty()) {
        let text = ctx.input(|i| {
            let mut text = "Dropping files:\n".to_owned();
            for file in &i.raw.hovered_files {
                if let Some(path) = &file.path {
                    write!(text, "\n{}", path.display()).ok();
                } else if !file.mime.is_empty() {
                    write!(text, "\n{}", file.mime).ok();
                } else {
                    text += "\n???";
                }
            }
            text
        });

        let painter =
            ctx.layer_painter(LayerId::new(Order::Foreground, Id::new("file_drop_target")));

        let screen_rect = ctx.screen_rect();
        painter.rect_filled(screen_rect, 0.0, Color32::from_black_alpha(192));
        painter.text(
            screen_rect.center(),
            Align2::CENTER_CENTER,
            text,
            TextStyle::Heading.resolve(&ctx.style()),
            Color32::WHITE,
        );
    }
}

impl TracerViewerApp {
    fn build_file_button(&mut self, ctx: &Context, ui: &mut Ui) {
        if ui.button("Open file…").clicked() {
            if let Some(path) = rfd::FileDialog::new().pick_file() {
                self.picked_path = Some(path.display().to_string());
            }
        }

        if let Some(picked_path) = &self.picked_path {
            ui.horizontal(|ui| {
                ui.label("Picked file:");
                ui.monospace(picked_path);
            });
        }

        // Show dropped files (if any):
        if !self.dropped_files.is_empty() {
            ui.group(|ui| {
                ui.label("Dropped files:");

                for file in &self.dropped_files {
                    let mut info = if let Some(path) = &file.path {
                        path.display().to_string()
                    } else if !file.name.is_empty() {
                        file.name.clone()
                    } else {
                        "???".to_owned()
                    };

                    let mut additional_info = vec![];
                    if !file.mime.is_empty() {
                        additional_info.push(format!("type: {}", file.mime));
                    }
                    if let Some(bytes) = &file.bytes {
                        additional_info.push(format!("{} bytes", bytes.len()));
                    }
                    if !additional_info.is_empty() {
                        info += &format!(" ({})", additional_info.join(", "));
                    }

                    ui.label(info);
                }
            });
        }
    }

    fn parse_file_worker(&mut self, path: PathBuf, on_done_tx: mpsc::SyncSender<BufferValue>) {
        let file_name = path.file_name().unwrap().to_str().unwrap().to_string();

        let handle = thread::spawn(move || {
            let file_data = fs::read_to_string(path).unwrap();

            let parse_result = parse(&file_data);

            let visible = generate_visibility(&parse_result);
            let data_indicies = generate_indicies(&visible, &parse_result);

            // callback(parse(&file_data));
            let _ = on_done_tx.send(Buffer {
                data_count: visible.clone().into_iter().filter(|&e| e).count(),
                visible,
                data_indicies,
                data: Ok(parse_result),
            });
        });

        self.threads.push((Some(handle), file_name));
    }
}

fn generate_visibility(messages: &Vec<CanMessage>) -> Vec<bool> {
    messages.iter().map(|e| !e.parent.is_some()).collect()
}

fn generate_indicies(mask: &Vec<bool>, messages: &Vec<CanMessage>) -> Vec<usize> {
    let mut dropped = mask.iter();

    messages
        .iter()
        .enumerate()
        .filter_map(|(i, _)| {
            if *dropped.next().unwrap() {
                return Some(i);
            }

            None
        })
        .collect()
}

fn find_empty_name(tree: &DockState<String>, name: &String) -> String {
    if let Some(_) = tree.find_tab(&name) {
        return find_empty_name(tree, &name.clone().add("1"));
    }

    name.clone()
}

impl eframe::App for TracerViewerApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            // let mut added_nodes = Vec::new();

            DockArea::new(&mut self.tree)
                // .show_add_buttons(true)
                .style({
                    let mut style = Style::from_egui(ctx.style().as_ref());

                    style.tab_bar.fill_tab_bar = true;
                    style
                })
                .show(ctx, &mut self.buffers);

            // self.build_file_button(ctx, ui);

            preview_files_being_dropped(ctx);
            // ctx.inspection_ui(ui);

            // Collect dropped files:
            ctx.input(|i| {
                if !i.raw.dropped_files.is_empty() {
                    let dropped_files = i.raw.dropped_files.clone();

                    for dropped_file in &dropped_files {
                        if let Some(path) = &dropped_file.path {
                            let file_name = path.file_name().unwrap().to_str().unwrap().to_string();

                            // let name = find_empty_name(&self.tree, &file_name);

                            if let Some(tab_location) = self.tree.find_tab(&file_name) {
                                self.tree.set_active_tab(tab_location);
                            } else {
                                // Open the file for editing:
                                self.tree.push_to_focused_leaf(file_name.clone());

                                self.parse_file_worker(path.clone(), self.on_done_tx.clone());
                            }
                        }
                    }
                }
            });
        });

        if !self.threads.is_empty() {
            let mut completed = vec![];
            let names = self.threads.iter().map(|e| e.1.clone());

            for (i, name) in names.enumerate() {
                if let Ok(result) = self.on_done_rc.try_recv() {
                    self.buffers.buffers.insert(name.clone(), result);

                    completed.push(i);
                }
            }

            for i in completed {
                let handle = std::mem::take(&mut self.threads[i].0);

                if let Some(handle) = handle {
                    handle.join().unwrap();
                }
            }

            self.threads.retain(|e| e.0.is_some())
        }
    }
}

impl std::ops::Drop for TracerViewerApp {
    fn drop(&mut self) {
        for (handle, show_tx) in self.threads.drain(..) {
            std::mem::drop(show_tx);

            handle.unwrap().join().unwrap();
        }
    }
}
