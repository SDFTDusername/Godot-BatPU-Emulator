use batpu_assembly::instruction::Instruction;
use batpu_assembly::InstructionVec;
use batpu_emulator::machine::Machine;
use godot::classes::file_access::ModeFlags;
use godot::classes::image::Format;
use godot::classes::{FileAccess, Image, ImageTexture, Node, TextureRect, Time};
use godot::prelude::*;

const OFF_COLOR: Color = Color::from_rgba8(158, 92, 56, 255);
const ON_COLOR: Color = Color::from_rgba8(242, 176, 111, 255);

#[derive(GodotClass)]
#[class(base=Node)]
struct MachineNode {
    base: Base<Node>,
    machine: Machine,

    tick_instantly: bool,
    previous_time: u64,
    remaining_micros: u64,

    run: bool,

    #[export] instructions_per_second: u32,

    #[export] screen_rect: Option<Gd<TextureRect>>
}

#[godot_api]
impl INode for MachineNode {
    fn init(base: Base<Node>) -> Self {
        Self {
            base,
            machine: Machine::new(),

            tick_instantly: false,
            previous_time: Time::singleton().get_ticks_usec(),
            remaining_micros: 0,
            
            run: false,
            
            instructions_per_second: 100,

            screen_rect: None
        }
    }

    fn process(&mut self, _delta: f64) {
        let current_time = Time::singleton().get_ticks_usec();

        if !self.run || self.tick_instantly {
            self.previous_time = current_time;
            self.remaining_micros = 0;

            if self.tick_instantly && self.run {
                self.tick_instantly = false;
                self.tick();
            }

            return;
        }

        let delta_time_micros = current_time - self.previous_time;
        self.previous_time = current_time;

        let tick_micros = delta_time_micros
            .saturating_mul(self.instructions_per_second as u64)
            .saturating_add(self.remaining_micros);

        let ticks_to_run = tick_micros / 1_000_000;
        self.remaining_micros = tick_micros % 1_000_000;

        for _ in 0..ticks_to_run {
            self.tick();
        }
    }
}

#[godot_api]
impl MachineNode {
    #[signal]
    fn ticked();

    #[func]
    fn is_running(&self) -> bool {
        self.run
    }

    #[func]
    fn get_program_counter(&self) -> u32 {
        self.machine.program_counter()
    }

    #[func]
    fn get_zero_flag(&self) -> bool {
        self.machine.zero_flag()
    }

    #[func]
    fn get_carry_flag(&self) -> bool {
        self.machine.carry_flag()
    }

    #[func]
    fn reset(&mut self) {
        self.machine.reset();
        self.update_screen(false);
    }

    #[func]
    fn start(&mut self) {
        self.tick_instantly = true;
        self.run = true;
    }

    #[func]
    fn stop(&mut self) {
        self.run = false;
        self.tick_instantly = false;
    }

    #[func]
    fn load_mc_file(&mut self, path: GString) {
        let mut file = FileAccess::open(&path.to_string(), ModeFlags::READ).unwrap();
        file.set_big_endian(true);

        let mut instructions = InstructionVec::with_capacity(file.get_length() as usize / 2);

        while !file.eof_reached() {
            let binary = file.get_16();
            let instruction = Instruction::instruction(binary).unwrap();
            instructions.push(instruction);
        }

        self.machine.set_instructions(instructions);
    }

    #[func]
    fn tick(&mut self) {
        self.machine.tick();
        self.update_screen(false);

        self.signals().ticked().emit();
    }

    #[func]
    fn update_screen(&mut self, force: bool) {
        let screen = self.machine.screen_mut();
        if force || screen.image_updated() {
            let image = screen.image();

            let width = screen.width() as isize;
            let height =  screen.height() as isize;

            let mut rgb_image = Image::create(width as i32, height as i32, false, Format::RGB8).unwrap();

            for x in 0..width {
                for y in 0..height {
                    let (byte, bit) = screen.get_index(x, y);

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