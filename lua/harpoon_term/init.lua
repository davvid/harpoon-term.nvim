local M = {}

local config = {
    cmds = {},
    enter_on_sendcmd = true,
    border = 'rounded',
    title = 'Terminal',
    title_pos = 'center',
    style = 'minimal',
    ui_width_ratio = 0.8,
    ui_height_ratio = 0.8,
    ui_fallback_width = 88,
    ui_fallback_height = 42,
    ui_max_width = nil,
    ui_max_height = nil,
}
-- Internal global state
M.harpoon_term_augroup = vim.api.nvim_create_augroup('HarpoonTerm', {})
M.config = config
M.current_win_id = nil
M.current_buf_id = nil
M.current_terminal = nil

local terminals = {}

function M.setup(opts)
    for key, value in pairs(opts) do
        M.config[key] = value
    end
end

function M.get_config(opts)
    return vim.tbl_extend('force', M.config, opts or {})
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
            floating_window = false,
        }
        terminals[args.idx] = term_handle
    end
    return term_handle
end

local function get_first_empty_slot()
    for idx, cmd in pairs(M.config.cmds) do
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
        M.current_buf_id = term_handle.buf_id
        M.current_terminal = idx
        if M.current_win_id then
            term_handle.floating_window = true
        end
    end
end

function M.send_command(idx, cmd, ...)
    M._send_command(false, idx, cmd, ...)
end

function M.send_command_to_floating_window(idx, cmd, ...)
    M._send_command(true, idx, cmd, ...)
end

function M._send_command(float, idx, cmd, ...)
    if idx == nil then
        idx = M.get_current_terminal()
    end
    local term_handle = M.find_terminal(idx)
    if term_handle == nil then
        return
    end

    if type(cmd) == 'number' then
        cmd = M.config.cmds[cmd]
    end

    if M.config.enter_on_sendcmd then
        cmd = cmd .. '\n'
    end

    if (float or term_handle.floating_window) and M.current_win_id == nil then
        M.toggle_floating_window(idx)
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
    return table.maxn(M.config.cmds)
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
    M.config.cmds[found_idx] = cmd
    M.emit_changed()
end

function M.set_command_list(new_list)
    for k in pairs(M.config.cmds) do
        M.config.cmds[k] = nil
    end
    for k, v in pairs(new_list) do
        M.config.cmds[k] = v
    end
    M.emit_changed()
end

function M.get_floating_window_size(opts)
    local width = opts.ui_fallback_width
    local height = opts.ui_fallback_height
    local win = vim.api.nvim_list_uis()
    if #win > 0 then
        width = math.floor(win[1].width * opts.ui_width_ratio)
        height = math.floor(win[1].height * opts.ui_height_ratio)
    end
    if opts.ui_max_width and width > opts.ui_max_width then
        width = opts.ui_max_width
    end
    if opts.ui_max_height and height > opts.ui_max_height then
        height = opts.ui_max_height
    end

    return width, height
end

function M._create_window(buf_id, opts)
    local width, height = M.get_floating_window_size(opts)
    local win_id = vim.api.nvim_open_win(buf_id, true, {
        relative = 'editor',
        title = opts.title,
        title_pos = opts.title_pos,
        row = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = opts.style,
        border = opts.border,
    })
    return win_id
end

function M.toggle_floating_window(idx, opts)
    if M.current_win_id and M.close_floating_window() then
        return
    end
    opts = M.get_config(opts)
    if idx == nil then
        idx = M.get_current_terminal()
    end
    local term_handle = M.find_terminal(idx)
    if term_handle == nil then
        return
    end

    local win_id = M._create_window(term_handle.buf_id, opts)
    if win_id ~= 0 then
        term_handle.floating_window = true
        M.current_win_id = win_id
        M.current_buf_id = term_handle.buf_id
        M.current_terminal = idx

        -- Close the window when ESC or Ctrl-C is pressed.
        vim.keymap.set('n', '<ESC>', function()
            M.close_floating_window()
        end, { buffer = term_handle.buf_id, silent = true })

        vim.keymap.set('n', '<C-c>', function()
            M.close_floating_window()
        end, { buffer = term_handle.buf_id, silent = true })

        -- Clear state when the terminal exits (e.g. when typing "exit").
        vim.api.nvim_create_autocmd({ 'TermClose' }, {
            group = M.harpoon_term_augroup,
            buffer = term_handle.buf_id,
            callback = function()
                M.close_floating_window()
                term_handle.floating_window = false
            end,
        })
    end
end

function M.get_current_terminal()
    if M.current_terminal == nil then
        M.current_terminal = 1
    end
    return M.current_terminal
end

function M.close_floating_window()
    local closed = false
    if M.current_win_id and vim.api.nvim_win_is_valid(M.current_win_id) then
        vim.api.nvim_win_close(M.current_win_id, true)
        closed = true
    end
    M.current_win_id = nil

    return closed
end

return M
