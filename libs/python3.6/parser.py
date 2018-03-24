def split_byte_to_lines(input_byte, linebreak='\n'):
    lines = []

    for line in input_byte.decode('utf8').split(linebreak):
            lines.append(line.strip())

    return lines
