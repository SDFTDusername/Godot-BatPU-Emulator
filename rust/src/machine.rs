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

    speed_accum_start: u64,
    sum_actual_ticks: f64,
    sum_ideal_ticks: f64,
    average_tick_duration: Option<f64>,

    run: bool,
    
    #[var] speed_percentage: f32,

    #[export] instructions_per_second: u32,
    #[export] speed_interval_micros: u32,

    #[export] screen_rect: Option<Gd<TextureRect>>
}

#[godot_api]
impl INode for MachineNode {
    fn init(base: Base<Node>) -> Self {
        let current_time = Time::singleton().get_ticks_usec();
        
        Self {
            base,
            machine: Machine::new(),

            tick_instantly: false,
            
            previous_time: current_time,
            remaining_micros: 0,
            
            speed_accum_start: current_time,
            sum_actual_ticks: 0.0,
            sum_ideal_ticks: 0.0,
            average_tick_duration: None,
            
            speed_percentage: 0.0,

            run: false,

            instructions_per_second: 100,
            speed_interval_micros: 500_000, // 0.5 seconds

            screen_rect: None
        }
    }

    fn process(&mut self, _delta: f64) {
        self.run_ticks();
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
        
        self.reset_time_fields();
        self.speed_percentage = 0.0;
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
                    let (byte, bit) = screen.get_index(x, height - y - 1);

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

    #[func]
    fn set_controller_value(&mut self, index: u32, value: bool) {
        let controller = self.machine.controller_mut();

        match index {
            7 => controller.start = value,
            6 => controller.select = value,

            5 => controller.a = value,
            4 => controller.b = value,

            3 => controller.up = value,
            2 => controller.right = value,
            1 => controller.down = value,
            0 => controller.left = value,

            _ => panic!("Unknown controller index {}", index)
        };
    }

    #[func]
    fn get_registers(&self) -> PackedByteArray {
        PackedByteArray::from(self.machine.registers())
    }

    #[func]
    fn get_memory(&self) -> PackedByteArray {
        PackedByteArray::from(self.machine.memory())
    }

    fn reset_time_fields(&mut self) {
        let current_time = Time::singleton().get_ticks_usec();
        
        self.previous_time = current_time;
        self.remaining_micros = 0;

        self.speed_accum_start = current_time;
        self.sum_actual_ticks = 0.0;
        self.sum_ideal_ticks = 0.0;
        self.average_tick_duration = None;
    }
    
    fn run_ticks(&mut self) {
        if !self.run || self.tick_instantly {
            self.reset_time_fields();

            if self.tick_instantly && self.run {
                self.tick_instantly = false;
                self.tick();
            }

            return;
        }
        
        let current_time = Time::singleton().get_ticks_usec();

        let delta_time = current_time - self.previous_time;
        self.previous_time = current_time;

        let tick_micros = delta_time
            .saturating_mul(self.instructions_per_second as u64)
            .saturating_add(self.remaining_micros);

        let mut ticks_to_run = tick_micros / 1_000_000;
        self.remaining_micros = tick_micros % 1_000_000;

        // Cap ticks to run
        if let Some(average_tick_duration) = self.average_tick_duration {
            let max_ticks = (delta_time as f64 / average_tick_duration) as u64;
            
            if ticks_to_run > max_ticks {
                let removed = ticks_to_run - max_ticks;
                let micros_reclaim = removed
                    .saturating_mul(1_000_000)
                    / (self.instructions_per_second as u64);
                
                self.remaining_micros = self.remaining_micros.saturating_add(micros_reclaim);
                ticks_to_run = max_ticks;
            }
        }
        
        let loop_start = Time::singleton().get_ticks_usec();
        
        for _ in 0..ticks_to_run {
            self.tick();
        }
        
        let loop_duration = Time::singleton().get_ticks_usec()
            .saturating_sub(loop_start);
        
        let this_average = if ticks_to_run > 0 {
            loop_duration as f64 / ticks_to_run as f64
        } else {
            0.0
        };
        
        self.average_tick_duration = Some(
            self.average_tick_duration.map_or(this_average, |previous| previous * 0.9 + this_average * 0.1)
        );

        let ideal_ticks = (self.instructions_per_second as f64)
            * (delta_time as f64 / 1_000_000.0);

        self.sum_actual_ticks += ticks_to_run as f64;
        self.sum_ideal_ticks += ideal_ticks;

        // Update speed percentage
        if current_time - self.speed_accum_start >= self.speed_interval_micros as u64 {
            self.speed_percentage = if self.sum_ideal_ticks > 0.0 {
                ((self.sum_actual_ticks / self.sum_ideal_ticks) * 100.0) as f32
            } else {
                100.0
            };

            self.sum_actual_ticks = 0.0;
            self.sum_ideal_ticks = 0.0;
            self.speed_accum_start = current_time;
        }
    }
}