use floem::{
    id::Id,
    kurbo::Rect,
    taffy,
    view::{ChangeFlags, View},
};

/// A simple wrapper around another View. See [`container`]
pub struct DropArea<V: View> {
    id: Id,
    child: V,
}

/// A simple wrapper around another View
///
/// A [`Container`] is useful for wrapping another [View](floem::view::View). This is often useful for allowing another
/// set of styles completely separate from the View that is being wrapped.
pub fn drop_area<V: View>(child: V) -> DropArea<V> {
    DropArea {
        id: Id::next(),
        child,
    }
}

impl<V: View> View for DropArea<V> {
    fn id(&self) -> Id {
        self.id
    }

    fn child(&self, id: Id) -> Option<&dyn View> {
        if self.child.id() == id {
            Some(&self.child)
        } else {
            None
        }
    }

    fn child_mut(&mut self, id: Id) -> Option<&mut dyn View> {
        if self.child.id() == id {
            Some(&mut self.child)
        } else {
            None
        }
    }

    fn children(&self) -> Vec<&dyn View> {
        vec![&self.child]
    }

    fn children_mut(&mut self) -> Vec<&mut dyn View> {
        vec![&mut self.child]
    }

    fn debug_name(&self) -> std::borrow::Cow<'static, str> {
        "Container".into()
    }

    fn update(
        &mut self,
        _cx: &mut floem::context::UpdateCx,
        _state: Box<dyn std::any::Any>,
    ) -> floem::view::ChangeFlags {
        ChangeFlags::empty()
    }

    fn layout(&mut self, cx: &mut floem::context::LayoutCx) -> taffy::prelude::Node {
        cx.layout_node(self.id, true, |cx| vec![self.child.layout_main(cx)])
    }

    fn compute_layout(&mut self, cx: &mut floem::context::LayoutCx) -> Option<Rect> {
        Some(self.child.compute_layout_main(cx))
    }

    fn event(
        &mut self,
        cx: &mut floem::context::EventCx,
        id_path: Option<&[Id]>,
        event: floem::event::Event,
    ) -> bool {
        if let floem::event::Event::DroppedFile(path) = &event {
            // self.

            println!("DROPPED FILE");
        }

        if cx.should_send(self.child.id(), &event) {
            self.child.event_main(cx, id_path, event)
        } else {
            false
        }
    }

    fn paint(&mut self, cx: &mut floem::context::PaintCx) {
        self.child.paint_main(cx);
    }
}
