-- Integração Leaf Markdown Viewer.
-- Abre um preview com `leaf -w <arquivo>` num split vertical à direita,
-- com toggle por arquivo (um único terminal Leaf por buffer Markdown).
--
-- Estado indexado pelo buffer Markdown (não pelo nº de janela, que pode
-- mudar). A limpeza (janela fechada manualmente, terminal encerrado ou
-- buffer Markdown apagado) zera o estado e mata o processo leaf.

local M = {}

---@type table<integer, {leaf_buf: integer, job_id: integer, augroup: integer}>
local state = {}

-- forward decl: cleanup referencia close_preview (definido abaixo).
local close_preview

--- Fecha o preview (janela + terminal + processo) de um buffer Markdown.
---@param md_buf integer
function cleanup(md_buf)
  close_preview(md_buf)
end

local function notify(msg, level)
  vim.notify(msg, level, { title = "Leaf" })
end

--- Fecha a janela do preview (via `q` ou toggle) e limpa tudo.
---@param md_buf integer
close_preview = function(md_buf)
  local st = state[md_buf]
  if not st then
    return
  end
  state[md_buf] = nil
  -- Fechar janelas que mostram o terminal (evita janela vazia coitada).
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == st.leaf_buf then
      pcall(vim.api.nvim_win_close, w, true)
    end
  end
  if st.leaf_buf and vim.api.nvim_buf_is_valid(st.leaf_buf) and vim.bo[st.leaf_buf].buflisted then
    pcall(vim.api.nvim_buf_delete, st.leaf_buf, { force = true })
  end
  if st.job_id then
    pcall(vim.fn.jobstop, st.job_id)
  end
  pcall(vim.api.nvim_del_augroup_by_id, st.augroup)
end

--- Valida o buffer/caminho atual; retorna caminho absoluto ou nil.
---@return string|nil path
local function current_markdown_path()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "markdown" or vim.bo[buf].buftype ~= "" then
    notify("Leaf: o buffer atual não é um arquivo Markdown.", vim.log.levels.WARN)
    return nil
  end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    notify("Leaf: salve o arquivo antes de abrir o preview.", vim.log.levels.WARN)
    return nil
  end
  if vim.fn.filereadable(path) == 0 then
    notify("Leaf: arquivo não existe ou não pode ser lido.", vim.log.levels.WARN)
    return nil
  end
  return path
end

local function open_preview(md_buf, path)
  -- Split vertical à direita.
  vim.cmd("rightbelow vnew")
  local win = vim.api.nvim_get_current_win()
  local augroup = vim.api.nvim_create_augroup("leaf_" .. md_buf, { clear = true })
  local leaf_buf = vim.api.nvim_get_current_buf()
  state[md_buf] = { leaf_buf = leaf_buf, job_id = nil, augroup = augroup }

  -- Termopen com lista de args: seguro com espaços/caracteres especiais
  -- (sem shell, sem concatenação).
  state[md_buf].job_id = vim.fn.termopen({ "leaf", "-w", path }, { buf = leaf_buf })

  -- Buffer-local: `q` fecha só o preview (não afeta outros terminais).
  vim.keymap.set("n", "q", function()
    close_preview(md_buf)
  end, { buffer = leaf_buf, silent = true, nowait, desc = "Leaf: fechar preview" })

  -- Terminal encerrou sozinho (usuário saiu do leaf): fechar o preview.
  vim.api.nvim_create_autocmd("TermClose", {
    group = augroup,
    buffer = leaf_buf,
    callback = function()
      -- Defer: dá tempo do Neovim terminar de fechar o job antes de
      -- deletar o buffer do terminal.
      vim.schedule(function()
        if state[md_buf] then
          close_preview(md_buf)
        end
      end)
    end,
  })

  -- Usuário fechou a janela/split manualmente: matar
  -- o processo leaf para não deixar órfão rodando sem janela.
  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = tostring(win),
    callback = function()
      close_preview(md_buf)
    end,
  })

  vim.api.nvim_win_set_buf(win, leaf_buf)
  vim.api.nvim_set_option_value("winfixbuf", true, { win = win })

  -- Foco volta para o buffer Markdown.
  vim.api.nvim_set_current_win(vim.fn.bufwinid(md_buf))

  -- Buffer Markdown apagado: mata o Leaf para não deixar processo órfão.
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = augroup,
    buffer = md_buf,
    callback = function()
      cleanup(md_buf)
    end,
  })
end

-- Toggle: fecha o preview se estiver aberto; (re)abre caso contrário.
function M.toggle()
  local md_buf = vim.api.nvim_get_current_buf()
  local path = current_markdown_path()
  if not path then
    return
  end
  if vim.fn.exepath("leaf") == "" then
    notify("Leaf: executável `leaf` não encontrado no $PATH.", vim.log.levels.ERROR)
    return
  end

  local st = state[md_buf]
  if st and vim.fn.bufwinid(st.leaf_buf) ~= -1 then
    -- Preview aberto: fecha.
    close_preview(md_buf)
    return
  end
  -- Sem preview (ou estado órfão após fechar o split): encerra o Leaf
  -- antigo, se houver, e abre um terminal novo.
  if st then
    close_preview(md_buf)
  end
  open_preview(md_buf, path)
end

function M.setup()
  if vim.g.__leaf_setup then
    return
  end
  vim.g.__leaf_setup = true

  vim.api.nvim_create_user_command("LeafToggle", function()
    M.toggle()
  end, { desc = "Toggle Markdown preview with Leaf" })
end

return M
