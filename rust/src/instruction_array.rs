use batpu_assembly::InstructionVec;
use godot::builtin::{GString, PackedStringArray};
use godot::meta::ToGodot;
use godot::obj::Gd;
use godot::prelude::godot_api;
use godot::register::GodotClass;
use std::error::Error;

#[derive(GodotClass)]
#[class(no_init)]
pub struct InstructionArray {
    pub instructions: Option<InstructionVec>,
    pub errors: Option<Vec<Box<dyn Error>>>
}

#[godot_api]
impl InstructionArray {
    pub fn new_instructions(instructions: InstructionVec) -> Gd<Self> {
        Gd::from_object(
            Self {
                instructions: Some(instructions),
                errors: None
            }
        )
    }

    pub fn new_errors(errors: Vec<Box<dyn Error>>) -> Gd<Self> {
        Gd::from_object(
            Self {
                instructions: None,
                errors: Some(errors)
            }
        )
    }

    #[func]
    pub fn has_errors(&self) -> bool {
        self.errors.is_some()
    }

    #[func]
    pub fn get_errors(&self) -> PackedStringArray {
        match self.errors {
            Some(ref errors) => {
                let messages = errors
                    .iter()
                    .map(|error| error.to_string().to_godot())
                    .collect::<Vec<GString>>();

                PackedStringArray::from(messages)
            },
            None => {
                PackedStringArray::new()
            }
        }
    }
}