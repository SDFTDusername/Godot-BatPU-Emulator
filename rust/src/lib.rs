mod machine_node;
mod instruction_array;

use godot::prelude::*;

struct EmulatorExtension;

#[gdextension]
unsafe impl ExtensionLibrary for EmulatorExtension {}
