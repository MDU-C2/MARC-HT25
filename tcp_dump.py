import socket

HOST = "192.168.100.1" # ändra dessa FREDRIK
PORT = 0000 # ändra dessa FREDRIK

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen(1)   # one connection at a time
    server.settimeout(1.0)

    print(f"Listening for TCP on {HOST}:{PORT} (Ctrl+C to quit)")
    try:
        while True:
            try:
                conn, addr = server.accept()
            except socket.timeout:
                continue

            print(f"Client connected: {addr}")
            conn.settimeout(1.0)

            try:
                while True:
                    try:
                        data = conn.recv(65535)
                        if not data:
                            print("Client disconnected.")
                            break
                        text = data.decode(errors="replace")
                        # text = egm.EgmRobot()
                        # text.ParseFromString(data)
                        print(f"Got TCP message from {addr}: {text}")

                    except socket.timeout:
                        continue
            finally:
                conn.close()

    except KeyboardInterrupt:
        print("\nStopped by user.")

    finally:
        server.close()


if __name__ == "__main__":
    main()
