use batpu_emulator::machine::Machine;
use godot::classes::image::Format;
use godot::classes::{Image, ImageTexture, Node, TextureRect};
use godot::prelude::*;

const OFF_COLOR: Color = Color::from_rgba8(158, 92, 56, 255);
const ON_COLOR: Color = Color::from_rgba8(242, 176, 111, 255);

#[derive(GodotClass)]
#[class(base=Node)]
struct MachineNode {
    base: Base<Node>,
    machine: Option<Machine>,
    
    #[export]
    screen_rect: Option<Gd<TextureRect>>
}

#[godot_api]
impl INode for MachineNode {
    fn init(base: Base<Node>) -> Self {
        Self {
            base,
            machine: None,

            screen_rect: None
        }
    }

    fn process(&mut self, _delta: f64) {
        self.tick()
    }

    fn ready(&mut self) {
        self.machine = Some(Machine::new(vec![]));
        self.tick()
    }
}

impl MachineNode {
    fn tick(&mut self) {
        if let Some(machine) = self.machine.as_mut() {
            machine.tick();
            self.update_screen();
        }
    }
    
    fn update_screen(&mut self) {
        if let Some(machine) = self.machine.as_mut() {
            let screen = machine.screen_mut();
            if screen.image_updated() {
                let image = screen.image();

                let width = screen.width();
                let height =  screen.height();

                let mut rgb_image = Image::create(width as i32, height as i32, false, Format::RGB8).unwrap();

                for x in 0..width {
                    for y in 0..height {
                        let index = x  + y * width;
                        let byte = index / 8;
                        let bit = index % 8;

                        let pixel = (image[byte] >> bit) == 1;
                        let color = if pixel {
                            ON_COLOR
                        } else {
                            OFF_COLOR
                        };

                        rgb_image.set_pixel(x as i32, y as i32, color);
                    }
                }

                let screen_texture = ImageTexture::create_from_image(&rgb_image).unwrap();
                if let Some(screen_rect) = self.screen_rect.as_mut() {
                    screen_rect.set_texture(&screen_texture);
                }

                screen.disable_image_updated();
            }
        }
    }
}