
function sevo.conf(c)
    print("-- configure info --")
    for k, v in pairs(c) do
        if k == "modules" then
            print(k .. ":")
            for l, m in pairs(v) do
                print(" " .. l .. " = " .. tostring(m))
            end
        else
            print(k .. " = " .. tostring(v))
        end
    end
    print("----- end -----")

    -- you can modify configure in here

    -- set writeable directory
    sevo.vfs.identity("test")
end
