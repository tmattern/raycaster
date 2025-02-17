# Programme Python pour générer une table de division pour 4096 divisé par les entiers de 1 à 200

def generate_div_table():
    div_table = []
    div_table.append(4096)
    for i in range(1, 200):
        div_value = 4096 // i
        div_table.append(div_value)
    return div_table

def format_asm_table(div_table):
    asm_lines = ["; Division table for 4096 divided by integers from 0 to 200",
                 "; Precomputed values",
                 "",
                 "DIV_TABLE"]
    for i in range(0, 200):
        asm_lines.append(f"        FDB     {div_table[i]}    ; 4096 / {i}")
    return "\n".join(asm_lines)

if __name__ == "__main__":
    div_table = generate_div_table()
    asm_table = format_asm_table(div_table)
    with open("div_table.asm", "w") as f:
        f.write(asm_table)
    print(f"Assembly table written to div_table.asm")