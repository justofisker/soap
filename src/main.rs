fn main() {
    if let Some(info) = parse_command_arguments() {
        pyramid(&info);
    }
}

struct PyramidInfo {
    size: usize,
    character: char,
}

impl Default for PyramidInfo {
    fn default() -> Self {
        PyramidInfo {
            size: 10,
            character: '*',
        }
    }
}

enum SoapOption {
    Size,
    Character,
    Help,
    None,
}

fn parse_command_arguments() -> Option<PyramidInfo> {
    let args: Vec<String> = std::env::args().collect();
    let mut arg_iter = args.iter();

    arg_iter.next();

    let mut info = PyramidInfo::default();

    while let Some(arg) = arg_iter.next() {
        let mut option = SoapOption::None;
        if arg.eq_ignore_ascii_case("-s") {
            option = SoapOption::Size;
        } else if arg.eq_ignore_ascii_case("--size") {
            option = SoapOption::Size;
        } else if arg.eq_ignore_ascii_case("-c") {
            option = SoapOption::Character;
        } else if arg.eq_ignore_ascii_case("--character") {
            option = SoapOption::Character;
        } else if arg.eq_ignore_ascii_case("-h") {
            option = SoapOption::Help;
        } else if arg.eq_ignore_ascii_case("--help") {
            option = SoapOption::Help;
        }

        match option {
            SoapOption::Size => {
                if let Some(size_string) = arg_iter.next() {
                    const MAX_SIZE: usize = 4096;
                    if let Ok(size) = size_string.parse::<usize>() {
                        if size <= MAX_SIZE {
                            info.size = size;
                        } else {
                            println!(
                                "Invalid size. Please use a number between 1 and {}",
                                MAX_SIZE
                            );
                        }
                    } else {
                        println!(
                            "Invalid size. Please use a number between 1 and {}",
                            MAX_SIZE
                        );
                        return None;
                    }
                } else {
                    println!("No size found. Need a size after '-s'.");
                    return None;
                }
            }
            SoapOption::Character => {
                if let Some(character_string) = arg_iter.next() {
                    if character_string.len() == 1 {
                        info.character = character_string.chars().next().unwrap();
                    } else {
                        println!("Please only use one character.");
                        return None;
                    }
                } else {
                    println!("No character found. Need a character after '-c'.");
                    return None;
                }
            }
            SoapOption::Help => {
                const HELP_MESSAGE: &'static str = concat!(
                    "Usage: soap [OPTION..]\n",
                    "\n",
                    "  -s, --size HEIGHT       Set the vertical size of the pyramid\n",
                    "  -c, --character CHAR    Set the character to be used in the pyramid\n",
                    "  -h, --help              Display this help and exit\n"
                );
                print!("{}", HELP_MESSAGE);
                return None;
            }
            SoapOption::None => {
                println!("Unknown option: {}", arg);
                return None;
            }
        }
    }

    Some(info)
}

fn pyramid(info: &PyramidInfo) {
    let mut buffer: Vec<char> = Vec::with_capacity((3 * info.size * info.size + info.size) / 2 + 1);
    for row in 0..info.size {
        for _column in 0..(info.size - row - 1) {
            buffer.push(' ');
        }
        for _column in 0..(row * 2 + 1) {
            buffer.push(info.character);
        }
        buffer.push('\n');
    }
    buffer.push('\0');
    print!("{}", String::from_iter(buffer.iter()));
}
