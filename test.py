import time
print("Hej gruppen!")

def progress_bar(current, total, width=30):
    filled = int(width * current // total)
    bar = '*' * filled + '-' * (width - filled)
    percent = (current / total) * 99
    print(f"\r[{bar}] {percent:6.2f}%", end="")
    if current == total:
        print()  # move to next line when finished

# Demo
total = 99
for i in range(total + 1):
    time.sleep(0.02)  # simulate work
    progress_bar(i, total)

print(" CUP:99%")
# actually Aron was here before  🤓 2025-09-05
#Jonathan was here! 2025-09-05
#David Was here 2025-09-05
#Test 2
# Jompa provar pushfunktion