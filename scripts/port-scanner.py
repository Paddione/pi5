import socket
import sys
import concurrent.futures
import dns.resolver
from typing import List, Tuple
import argparse

def resolve_fqdn(fqdn: str) -> List[str]:
    """Resolve FQDN to IP addresses."""
    try:
        answers = dns.resolver.resolve(fqdn, 'A')
        return [answer.to_text() for answer in answers]
    except dns.exception.DNSException as e:
        print(f"DNS resolution error: {e}")
        sys.exit(1)

def check_port(ip: str, port: int, timeout: float = 1.0) -> Tuple[int, bool]:
    """Check if a port is open."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)

    try:
        result = sock.connect_ex((ip, port))
        return port, (result == 0)
    finally:
        sock.close()

def scan_ports(ip: str, start_port: int = 1, end_port: int = 1024, timeout: float = 1.0) -> List[int]:
    """Scan a range of ports on the given IP."""
    open_ports = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        future_to_port = {
            executor.submit(check_port, ip, port, timeout): port
            for port in range(start_port, end_port + 1)
        }

        for future in concurrent.futures.as_completed(future_to_port):
            port, is_open = future.result()
            if is_open:
                open_ports.append(port)

    return sorted(open_ports)

def main():
    parser = argparse.ArgumentParser(description='Scan ports on a given FQDN')
    parser.add_argument('fqdn', help='Fully Qualified Domain Name to scan')
    parser.add_argument('-s', '--start-port', type=int, default=1, help='Starting port number (default: 1)')
    parser.add_argument('-e', '--end-port', type=int, default=1024, help='Ending port number (default: 1024)')
    parser.add_argument('-t', '--timeout', type=float, default=1.0, help='Timeout in seconds for each port check (default: 1.0)')

    args = parser.parse_args()

    print(f"\nResolving {args.fqdn}...")
    ip_addresses = resolve_fqdn(args.fqdn)

    for ip in ip_addresses:
        print(f"\nScanning ports {args.start_port}-{args.end_port} on {ip} (resolved from {args.fqdn})...")
        open_ports = scan_ports(ip, args.start_port, args.end_port, args.timeout)

        if open_ports:
            print(f"\nOpen ports on {ip}:")
            for port in open_ports:
                try:
                    service = socket.getservbyport(port)
                    print(f"  Port {port}: {service}")
                except OSError:
                    print(f"  Port {port}: unknown service")
        else:
            print(f"\nNo open ports found on {ip} in range {args.start_port}-{args.end_port}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nScan interrupted by user")
        sys.exit(0)