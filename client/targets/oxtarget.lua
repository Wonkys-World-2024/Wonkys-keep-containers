function Ox_target(private, entity)

    exports.ox_target:addLocalEntity(entity, {

        --================================================--
        -- OPEN CONTAINER
        --================================================--
        {
            name = "keep_container_open",
            icon = "fas fa-box",
            distance = 1.0,
            label = "Open Container",

            onSelect = function()
                OpenContainer(private, entity)
            end
        },

        --================================================--
        -- CHANGE PASSWORD
        --================================================--
        {
            name = "keep_container_change_password",
            icon = "fa-solid fa-key",
            distance = 1.0,
            label = "Change Password",

            onSelect = function()
                ChangePassword(private, entity)
            end
        },

        --================================================--
        -- TRANSFER OWNERSHIP
        --================================================--
        {
            name = "keep_container_transfer",
            icon = "fa-solid fa-right-left",
            distance = 1.0,
            label = "Transfer Ownership",

            onSelect = function()
                TransferOwnership(private, entity)
            end
        },

        --================================================--
        -- DELETE CONTAINER
        -- SUPER USER ONLY
        --================================================--
        {
            name = "keep_container_delete",
            icon = "fas fa-trash",
            distance = 1.0,
            label = "Delete Container",

            canInteract = function()
                return SuperUser()
            end,

            onSelect = function()
                if not SuperUser() then
                    Notification_c("You do not have permission to delete containers.", "error")
                    return
                end

                DeleteContainer(private, entity)
            end
        },

        --================================================--
        -- MOVE CONTAINER
        -- SUPER USER ONLY
        --================================================--
        {
            name = "keep_container_move",
            icon = "fa-solid fa-arrows-up-down-left-right",
            distance = 1.0,
            label = "Move Container",

            canInteract = function()
                return SuperUser()
            end,

            onSelect = function()
                if not SuperUser() then
                    Notification_c("You do not have permission to move containers.", "error")
                    return
                end

                MoveContainer(private, entity)
            end
        },

        --================================================--
        -- BOLTCUTTER
        -- JOB / GRADE CONTROLLED
        --================================================--
        {
            name = "keep_container_boltcutter",
            icon = "fa-solid fa-scissors",
            distance = 1.0,
            label = "Boltcutter (Police)",

            canInteract = function()
                return HasAccessToBoltCutter()
            end,

            onSelect = function()
                BoltCutter(private, entity)
            end
        }

    })
end