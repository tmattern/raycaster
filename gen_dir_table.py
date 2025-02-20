# Programme Python pour générer une table de division pour 4096 divisé par les entiers de 1 à 200
import math

def generate_dir_table():

    #dir_x = t[angle]
    #plane_x = t[angle+64 mod 256] /2
    #dir_y = t[angle+192 mod 256]
    #plane_y = dir_x / 2

    dir_x0 = -127
    dir_y0 = 0
    plane_x0 = 0
    plane_y0 = -63

    dir_table = []
    for deg in range(256):
        angle = deg * math.pi * 2 / 256
        dir_x = int(dir_x0 * math.cos(angle) - dir_y0 * math.sin(angle))
        dir_table.append( dir_x )

    return dir_table

def format_asm_table(dir_table):
    asm_lines = ["; Direction table dir_x, dir_y, plane_x, plane_y",
                 "; Precomputed values",
                 ";    dir_x = t[angle]",
                 ";    plane_x = t[angle+64 mod 256] /2",
                 ";    dir_y = t[angle+192 mod 256]",
                 ";    plane_y = dir_x / 2",
                 "",
                 "DIR_TABLE"]
    for angle in range(256):
        asm_lines.append(f"        FCB     {dir_table[angle]}")
    return "\n".join(asm_lines)

if __name__ == "__main__":
    dir_table = generate_dir_table()
    asm_table = format_asm_table(dir_table)
    with open("dir_table.asm", "w") as f:
        f.write(asm_table)
    print(f"Assembly table written to dir_table.asm")