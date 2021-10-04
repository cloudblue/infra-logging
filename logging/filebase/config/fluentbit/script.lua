function get_log_level(message)

    log_level = "UNDEFINED"
    if string.find(message, "INFO") or string.find(message, "INF]") or string.find(message, "info]") then
        log_level = "INFO"

    elseif string.find(message, "DEBUG") then
        log_level = "DEBUG"

    elseif string.find(message, "ERROR") or string.find(message, "ERR") or string.find(message, "error") then
        log_level = "ERROR"

    elseif string.find(message, "Warning") or string.find(message, "WARN") or string.find(message, "warn") then
        log_level = "WARNING"
    end
    return log_level
end

function get_is_exception(message)

    is_exception = nil

    if string.find(message, "exception") or string.find(message, "EXCEPTION ") or string.find(message, "Exception ") then
        is_exception = "true"
    end
    return is_exception
end

function ltrim(s)
    return s:match '^%s*(.*)'
end

function get_file_name(file)
    f = file:match("^.+/(.+)$")
    return f:match("(.+)-.+")
end

function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function append_fields(tag, timestamp, record)

    new_record = record
    new_record["tag"] = tag

    elastic_postfix = ""

    if record["kubernetes"] ~= nil then

        if record["kubernetes"]["host"] ~= nil then
            new_record["host"] = record["kubernetes"]["host"]
        else
            new_record["host"] = "unknown"
        end

        if record["kubernetes"]["namespace_name"] ~= nil then
            new_record["namespace"] = record["kubernetes"]["namespace_name"]
        else
            new_record["namespace"] = "unknown"
        end

        if record["kubernetes"]["pod_name"] ~= nil then
            if string.find(record["kubernetes"]["pod_name"], "bss%-worker") then
                new_record["podname"] = "bss-worker"
                new_record["podname_orig"] = record["kubernetes"]["pod_name"]
            else
                new_record["podname"] = record["kubernetes"]["pod_name"]
            end
        else
            new_record["podname"] = "unknown"
        end

        if record["kubernetes"]["container_name"] ~= nil then
            new_record["containername"] = record["kubernetes"]["container_name"]
        else
            new_record["containername"] = "unknown"
        end

        ---- elastic

        if record["kubernetes"]["labels"]["release"] ~= nil then
            new_record["release"] = record["kubernetes"]["labels"]["release"]
        end

        if record["kubernetes"]["labels"]["app"] ~= nil then
            new_record["app"] = record["kubernetes"]["labels"]["app"]
        elseif record["kubernetes"]["labels"]["service"] ~= nil then
            new_record["app"] = record["kubernetes"]["labels"]["service"]
        elseif record["kubernetes"]["labels"]["k8s-app"] ~= nil then
            new_record["app"] = record["kubernetes"]["labels"]["k8s-app"]
        elseif record["kubernetes"]["labels"]["component"] ~= nil then
            new_record["app"] = record["kubernetes"]["labels"]["component"]
        elseif record["kubernetes"]["labels"]["app.kubernetes.io/name"] ~= nil then
            new_record["app"] = record["kubernetes"]["labels"]["app.kubernetes.io/name"]
        end

        if record["kubernetes"]["pod_name"] ~= nil then
            if string.find(record["kubernetes"]["pod_name"], "bss%-worker") then
                elastic_postfix = "-bss-worker"
            elseif string.find(record["kubernetes"]["pod_name"], "oss%-node") then
                elastic_postfix = "-oss-node"
            elseif string.find(record["kubernetes"]["pod_name"], "bss%-scheduler") then
                elastic_postfix = "-bss-scheduler"
            elseif string.find(record["kubernetes"]["pod_name"], "flog") then
                elastic_postfix = "-" .. new_record["app"]
            end
        end

    else
        if record["filepath"] ~= nil then

            filename = get_file_name(record["filepath"])
            file_parts = mysplit(filename, "_")

            new_record["host"] = "unknown"
            new_record["podname"] = file_parts[1]
            new_record["namespace"] = file_parts[2]
            new_record["containername"] = file_parts[3]
        else
            new_record["host"] = "unknown"
            new_record["namespace"] = "unknown"
            new_record["podname"] = "unknown"
            new_record["containername"] = "unknown"
        end
    end

    if record["log"] ~= nil then

        new_record["log_level"] = get_log_level(record["log"])
        new_record["is_exception"] = get_is_exception(record["log"])

        i = 1
        new_record["message"] = ""
        new_record["logtag"] = ""

        if string.find(record["log"], "stdout") or string.find(record["log"], "stderr") then

            for token in string.gmatch(record["log"], "[^%s]+") do
                if i == 1 then
                    new_record["event_time"] = token
                elseif i == 2 then
                    new_record["stream"] = token
                elseif i == 3 then
                    new_record["logtag"] = token
                elseif i > 3 then
                    new_record["message"] = new_record["message"] .. " " .. token
                end
                i = i + 1
            end

            new_record["message"] = ltrim(new_record["message"])

        else
            new_record["event_time"] = record["time"]
            new_record["stream"] = record["stream"]
            new_record["message"] = record["log"]
        end

        new_record["message_k8s"] = new_record["event_time"] .. " " .. new_record["stream"] .. " " ..
                                        new_record["logtag"] .. " " .. new_record["message"]
    end

    -- let's compose the elasticsearch index name
    -- for some app we will have a dedicated index using elastic_postfix
    new_record["es_index"] = "ns" .. elastic_postfix
    if record["namespace"] ~= nil then
        namespace = record["namespace"]
        new_record["es_index"] = namespace .. elastic_postfix
        if record["index_strategy"] ~= nil then
            if record["index_strategy"] == "reduced" then
                namespace = namespace:gsub("(.*)-.*$", "%1")
                namespace = namespace:gsub("(.*)-.*$", "%1")
                new_record["es_index"] = namespace
            end
        end
    end

    -- clean records 

    if record["kubernetes"] ~= nil then
        new_record["kubernetes"] = nil
        new_record["kubernetes"] = {}
        new_record["kubernetes"]["namespace_name"] = new_record["namespace"]
        new_record["kubernetes"]["container_name"] = new_record["containername"]
        new_record["kubernetes"]["pod_name"] = new_record["podname"]
    end
    if record["log"] ~= nil then
        new_record["log"] = nil
    end
    if record["index_strategy"] ~= nil then
        new_record["index_strategy"] = nil
    end
    return 1, timestamp, new_record
end

