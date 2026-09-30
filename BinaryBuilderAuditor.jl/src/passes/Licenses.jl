"""
    licenses_present(scan::ScanResult)

Returns `true` if there are any files in `share/licenses`, `false` otherwise.
"""
function licenses_present(result::AuditResult)
    scan, pass_results = result.scan, result.pass_results
    num_licenses = 0
    for (path, st) in scan.files
        if startswith(path, "share/licenses") && isfile(st)
            push_result!(pass_results, "licenses_present", :success, path)
            num_licenses += 1
        end
    end
    if num_licenses == 0
        push_result!(pass_results, "licenses_present", :fail, "share/licenses")
    end
end
