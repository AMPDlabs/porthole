import Darwin

// MARK: - proc_info constants not exported to Swift
private let PROC_PIDLISTFDS: Int32 = 1
private let PROC_PIDFDSOCKETINFO: Int32 = 3
private let PROX_FDTYPE_SOCKET: UInt32 = 2
private let SOCKINFO_TCP: Int32 = 2
private let TSI_S_LISTEN: Int32 = 10

enum ProcessScanner {
static func buildPortProcessMap() -> [Int: (name: String, pid: Int)] {
    var map: [Int: (name: String, pid: Int)] = [:]

    let byteCount = proc_listallpids(nil, 0)
    print("[ProcessScanner] proc_listallpids byteCount=\(byteCount)")
    guard byteCount > 0 else { return map }

    var pids = [pid_t](repeating: 0, count: Int(byteCount) / MemoryLayout<pid_t>.size + 16)
    let filled = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
    print("[ProcessScanner] filled=\(filled)")
    guard filled > 0 else { return map }

    var fdSucceed = 0, fdFail = 0, sockFound = 0

    for i in 0..<Int(filled) {
        let pid = pids[i]
        guard pid > 0 else { continue }

        var nameBuf = [CChar](repeating: 0, count: 256)
        proc_name(pid, &nameBuf, 256)
        let name = String(cString: nameBuf)
        guard !name.isEmpty else { continue }

        let fdBytes = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        if fdBytes <= 0 { fdFail += 1; continue }
        fdSucceed += 1

        let fdCount = Int(fdBytes) / MemoryLayout<proc_fdinfo>.size
        var fdList = [proc_fdinfo](repeating: proc_fdinfo(), count: fdCount)
        proc_pidinfo(pid, PROC_PIDLISTFDS, 0, &fdList, fdBytes)

        for fd in fdList {
            guard fd.proc_fdtype == PROX_FDTYPE_SOCKET else { continue }

            var sockInfo = socket_fdinfo()
            let n = proc_pidfdinfo(pid, fd.proc_fd, PROC_PIDFDSOCKETINFO,
                                   &sockInfo, Int32(MemoryLayout<socket_fdinfo>.size))
            guard n > 0 else { continue }
            guard sockInfo.psi.soi_kind == SOCKINFO_TCP else { continue }

            let tcpsi = sockInfo.psi.soi_proto.pri_tcp
            guard tcpsi.tcpsi_state == TSI_S_LISTEN else { continue }

            let port = Int(tcpsi.tcpsi_ini.insi_lport.bigEndian)
            guard port > 0 else { continue }

            sockFound += 1
            if map[port] == nil {
                map[port] = (name: name, pid: Int(pid))
            }
        }
    }

    print("[ProcessScanner] fdSucceed=\(fdSucceed) fdFail=\(fdFail) sockFound=\(sockFound) mapped=\(map.count)")
    return map
}
} // enum ProcessScanner
