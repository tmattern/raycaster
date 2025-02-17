from datetime import datetime
import math

for i in range(int(960/16)):
    line = []
    for j in range(16):
        
        angle_rad = (i * 16.0 + j) * math.pi * 2.0 / 768.0
        val = round(math.sin(angle_rad) * 127)
        line.append(str(val))
    print(f"    FCB " + str.join(",", line))


import math

def generate_recip_tables():
    # 192 entrées pour 90 degrés (768/4)
    num_entries = 192
    
    sin_values = []
    cos_values = []
    
    print("; =============================================")
    print("; Tables (4096/|sin(x)|)/16 et (4096/|cos(x)|)/16")
    print("; Version: 1.0")
    print("; Date: 2025-01-26 16:51:59")
    print("; Auteur: tmattern")
    print("; =============================================")
    print(";")
    print("; 192 entrées pour 90 degrés")
    print("; Chaque colonne = 0.46875 degrés")
    print("; Table pour le premier quadrant uniquement")
    print("; Les autres quadrants sont déduits par symétrie:")
    print(";")
    print("; Pour sin(x):")
    print(";   0-191   (0°-90°)   : utiliser  valeur")
    print(";   192-383 (90°-180°) : utiliser  valeur(384-x)")
    print(";   384-575 (180°-270°): utiliser -valeur(x-384)")
    print(";   576-767 (270°-360°): utiliser -valeur(768-x)")
    print(";")
    print("; Pour cos(x):")
    print(";   0-191   (0°-90°)   : utiliser  valeur")
    print(";   192-383 (90°-180°) : utiliser -valeur(384-x)")
    print(";   384-575 (180°-270°): utiliser -valeur(x-384)")
    print(";   576-767 (270°-360°): utiliser  valeur(768-x)")
    print(";")
    print("        ALIGN 256")
    
    for i in range(num_entries):
        # Angle en radians (0.46875° par entrée)
        angle = (i * 90.0 / num_entries) * math.pi / 180.0
        
        sin = abs(256.0*math.sin(angle))
        cos = abs(256.0*math.cos(angle))
        
        if sin == 0:
            sin_val = 1023
        else:
            sin_val = min(round(20000 / sin), 1023)

        if cos == 0:
            cos_val = 1023
        else:
            cos_val = min(round(20000 / cos), 1023)
            
        sin_values.append(sin_val)
        cos_values.append(cos_val)
    
    # Affichage des valeurs sur deux colonnes (sin,cos) par groupes de 8 paires
    print("SIN_Q1  ; Premier quadrant (0°-90°)")
    for i in range(0, num_entries, 8):
        sin_group = sin_values[i:i+8]
        pairs = [f"{s}" for s in (sin_group)]
        print("        FDB " + ",".join(pairs))
    print("COS_Q1  ; Premier quadrant (0°-90°)")
    for i in range(0, num_entries, 8):
        cos_group = cos_values[i:i+8]
        pairs = [f"{c}" for c in (cos_group)]
        print("        FDB " + ",".join(pairs))


generate_recip_tables()