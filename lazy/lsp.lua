return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",

        "mfussenegger/nvim-dap",
        "jay-babu/mason-nvim-dap.nvim",
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",

        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
        "simrat39/rust-tools.nvim",
    },

    config = function()
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        local function on_attach(client, bufnr)
            local keymap = vim.keymap
            local keymap_opts = { buffer = bufnr, silent = true }

            keymap.set("n", "<leader>h", vim.lsp.buf.hover, keymap_opts)
            keymap.set("n", "<leader>h", vim.lsp.buf.hover, keymap_opts)
            keymap.set("n", "<a-CR>", vim.lsp.buf.code_action, keymap_opts)

            -- Code navigation and shortcuts
            keymap.set("n", "<leader>m", vim.diagnostic.open_float, keymap_opts)
            keymap.set("n", "<leader>M", function() vim.cmd.RustLsp('renderDiagnostic') end, keymap_opts)
            keymap.set("n", "gd", vim.lsp.buf.definition, keymap_opts)
            keymap.set("n", "gD", vim.lsp.buf.implementation, keymap_opts)
            keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, keymap_opts)
            keymap.set("n", "<leader>gr", ":Telescope lsp_references<cr>", keymap_opts)
            keymap.set("n", "g0", vim.lsp.buf.document_symbol, keymap_opts)
            keymap.set("n", "gW", vim.lsp.buf.workspace_symbol, keymap_opts)
            keymap.set("n", "<a-p>", vim.lsp.buf.signature_help, keymap_opts)
            keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, keymap_opts)
            keymap.set("n", "<leader>rn", vim.lsp.buf.rename, keymap_opts)
            keymap.set("n", "<leader>t", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, keymap_opts)

            -- Show diagnostic popup on cursor hover
            -- Nice but also annoying cause it overwrites actual popups
            -- local diag_float_grp = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true })
            -- vim.api.nvim_create_autocmd("CursorHold", {
                -- callback = function()
                    -- vim.diagnostic.open_float(nil, { focusable = false })
                -- end,
                -- group = diag_float_grp,
            -- })
            -- " Set updatetime for CursorHold
            -- " 300ms of no cursor movement to trigger CursorHold
            -- set updatetime=300
            -- vim.opt.updatetime = 1000
            --

            -- Goto previous/next diagnostic warning/error
            keymap.set("n", "]d", vim.diagnostic.goto_next, keymap_opts)
            keymap.set("n", "[d", vim.diagnostic.goto_prev, keymap_opts)
        end

        require("fidget").setup({})
        require("mason").setup()
        require("mason-nvim-dap").setup(
            {
                ensure_installed =
                {
                    "codelldb"
                }
            }
        )
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "phpactor",
                "omnisharp",
                "rust_analyzer",
            },
            compilationDatabasePath = './build',
            handlers = {
                function(server_name) -- default handler (optional)
                    require("mason-nvim-lint.install").try_install("cpplint")

                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,

                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                diagnostics = {
                                    globals = { "vim", "it", "describe", "before_each", "after_each" },
                                }
                            }
                        }
                    }
                end,

                ["rust_analyzer"] = function()
                    require('lspconfig').rust_analyzer.setup {
                        on_attach = on_attach,
						cmd_env = { CARGO_TARGET_DIR = "target/rust-analyzer-check" },

						settings = {
							["rust-analyzer"] = {
								imports = {
									granularity = {
                                        enforce = true,
                                        group  = "module",
                                    },
								},

								rustfmt = {
									enableRangeFormatting = true,
									rangeFormatting = {
										enable = true,
									},
								},

								inlayHints = {
									bindingModeHints = { enable = true },
									closureReturnTypeHints = { enable = true },
									lifetimeElisionHints = { useParameterNames = true, enable = "skip_trivial" },
									closingBraceHints = { minLines = 0 },
									parameterHints = { enable = false },
									maxLength = 999,
								},
							},
						},
					}
                end,
                }
            })

        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {
                expand = function(args)
                    require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                ['<C-n'] = cmp.mapping.select_next_item(cmp_select),
                ['<Enter>'] = cmp.mapping.confirm({ select = true }),
                ["<C-Space>"] = cmp.mapping.complete(),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'luasnip' }, -- For luasnip users.
            }, {
                { name = 'buffer' },
            })
        })

        vim.diagnostic.config({
            update_in_insert = false,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })

        local dap = require("dap")
        require("dapui").setup(
            {
                layouts =
                {
                    {
                        elements =
                        {
                            { id = "repl", size = 0.1},
                            { id = "console", size = 0.3},
                            { id = "scopes", size = 0.5},
                        },
                        size = 0.25,
                        position = "bottom"
                    },
                    {
                        elements =
                        {
                            "watches",
                            "stacks",
                            "breakpoints",
                        },
                        size = 40,
                        position = "left"
                    }
                }
            }
        )

        -- DAP
        dap.adapters.codelldb =
        {
            type = "executable",
            command = "codelldb",
        }

        dap.configurations.cpp =
        {
          {
            name = "Launch file",
            type = "codelldb",
            request = "launch",
            program = function()
              return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
          },
        }

        local last_config = nil
        dap.listeners.after.event_initialized["store_config"] = function(session)
            last_config = session.config
        end

        local function dap_run_last()
          if last_config then
            dap.run(last_config)
          else
            dap.continue()
          end
        end

        dap.configurations.c = dap.configurations.cpp

        keymap = vim.keymap
        -- nvim dap
        keymap.set("n", "<leader>ddb", dap.toggle_breakpoint, { desc ="Toggle  Break" })
        keymap.set("n", "<leader>ddc", dap.continue, { desc ="Continue" })
        -- keymap.set("n", "<leader>ddr", dap.repl.open, { desc ="Inspect" })
        keymap.set("n", "<leader>ddk", dap.terminate, { desc ="Kill" })
        keymap.set("n", "<leader>ddn", dap.step_over, { desc ="Step Next" })
        keymap.set("n", "<leader>ddi", dap.step_into, { desc ="Step Into" })
        keymap.set("n", "<leader>ddo", dap.step_into, { desc ="Step Out" })
        keymap.set("n", "<leader>ddl", dap_run_last, { desc ="Run Last" })
        keymap.set("n", "<leader>dds", dap_run_last, { desc ="Run Last Stored" })

        -- nvim dap ui
        local dapui = require("dapui")
        keymap.set("n", "<leader>dd[", dapui.open, { desc ="Open UI" })
        keymap.set("n", "<leader>dd]", dapui.close, { desc ="Close UI" })
    end

}
