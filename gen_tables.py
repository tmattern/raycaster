from datetime import datetime
import math

for i in range(int(640/16)):
    line = []
    for j in range(16):
        
        angle_rad = (i * 16.0 + j) * math.pi * 2.0 / 512.0
        val = round(math.sin(angle_rad) * 127)
        line.append(str(val))
    print(f"    FCB " + str.join(",", line))
