import socket
import egm_pb2 as egm

HOST = "127.0.0.1"  # localhost
PORT = 6510         # change if you want

def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((HOST, PORT))
    sock.settimeout(1.0)  # allow Ctrl+C to break the loop

    print(f"Listening for UDP on {HOST}:{PORT} (Ctrl+C to quit)")
    try:
        while True:
            try:
                data, addr = sock.recvfrom(65535)
                # text = data.decode(errors="replace")
                text =egm.EgmRobot()
                text.ParseFromString(data)
                print(f"Got UDP message from {addr}: {text}")
            except socket.timeout:
                continue  # just loop back and check again
    except KeyboardInterrupt:
        print("\nStopped by user.")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
