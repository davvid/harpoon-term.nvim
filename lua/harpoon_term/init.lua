local M = {}

local global_config = {
    cmds = {},
    enter_on_sendcmd = true,
    save_on_change = true,
}

local terminals = {}

function M.setup(config)
    for key, value in pairs(config) do
        global_config[key] = value
    end
end

function M.create_terminal(create_with)
    if not create_with then
        create_with = ':terminal'
    end
    local current_id = vim.api.nvim_get_current_buf()

    vim.cmd(create_with)
    local buf_id = vim.api.nvim_get_current_buf()
    local term_id = vim.b.terminal_job_id
    if term_id == nil then
        return nil
    end

    -- Make sure the term buffer has "hidden" set so it doesn't get thrown
    -- away and cause an error
    vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf_id })

    -- Resets the buffer back to the old one
    vim.api.nvim_set_current_buf(current_id)
    return buf_id, term_id
end

function M.find_terminal(args)
    if type(args) == 'number' then
        args = { idx = args }
    end
    local term_handle = terminals[args.idx]
    if not term_handle or not vim.api.nvim_buf_is_valid(term_handle.buf_id) then
        local buf_id, term_id = M.create_terminal(args.create_with)
        if buf_id == nil then
            error('Failed to find and create terminal.')
            return
        end

        term_handle = {
            buf_id = buf_id,
            term_id = term_id,
        }
        terminals[args.idx] = term_handle
    end
    return term_handle
end

local function get_first_empty_slot()
    for idx, cmd in pairs(global_config.cmds) do
        if cmd == '' then
            return idx
        end
    end
    return M.get_length() + 1
end

function M.goto_terminal(idx)
    local term_handle = M.find_terminal(idx)
    if term_handle ~= nil then
        vim.api.nvim_set_current_buf(term_handle.buf_id)
    end
end

function M.send_command(idx, cmd, ...)
    local term_handle = M.find_terminal(idx)
    if term_handle == nil then
        return
    end

    if type(cmd) == 'number' then
        cmd = global_config.cmds[cmd]
    end

    if global_config.enter_on_sendcmd then
        cmd = cmd .. '\n'
    end

    if cmd then
        vim.api.nvim_chan_send(term_handle.term_id, string.format(cmd, ...))
    end
end

function M.clear_all()
    for _, term in ipairs(terminals) do
        vim.api.nvim_buf_delete(term.buf_id, { force = true })
    end
    terminals = {}
end

function M.get_length()
    return table.maxn(global_config.cmds)
end

function M.valid_index(idx)
    if idx == nil or idx > M.get_length() or idx <= 0 then
        return false
    end
    return true
end

function M.emit_changed() end

function M.add_command(cmd)
    local found_idx = get_first_empty_slot()
    global_config.cmds[found_idx] = cmd
    M.emit_changed()
end

function M.set_command_list(new_list)
    for k in pairs(global_config.cmds) do
        global_config.cmds[k] = nil
    end
    for k, v in pairs(new_list) do
        global_config.cmds[k] = v
    end
    M.emit_changed()
end

return M
