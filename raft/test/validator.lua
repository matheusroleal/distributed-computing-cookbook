local VALIDATOR = {}

local function math_types_equivalent()
  local swagger_struct = {} -- converting to math.types
  for i=1,#struct.fields do
    local tmp_type = struct.fields[i].type
    if tmp_type == "double" then
       tmp_type = "float"
    elseif tmp_type == "int" then
      tmp_type = "integer"
    end
    swagger_struct[struct.fields[i].name] = tmp_type
  end
  return swagger_struct
end

function VALIDATOR.validate_client(params,fname,iface_args)
  local valid = true
  local inputs = {}
  local reasons = ""
  local swagger_struct = math_types_equivalent()
  for i=1,#iface_args do
    local arg_direc = iface_args[i].direction
    if arg_direc == "in" or arg_direc == "inout" then
      local arg_type = iface_args[i].type
      table.insert(inputs,arg_type)
    end
  end
  if not (#params == #inputs) then
    local reason = string.format("Method '%s' should receive %i args, but received %i instead",fname,#inputs,#params)
    -- -- print("[ERROR] Invalid request! " .. reason)
    valid = false
    reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
  else
    for i=1,#inputs do
      if inputs[i] == "int" or inputs[i] == "double" then -- number case
        local inner_valid = true
        if type(params[i]) ~= "number" then
          local tmp = tonumber(params[i])
          if tmp == nil then
            local reason = string.format("#%i arg of method '%s' must be a valid number format and not %s",i,fname,type(params[i]))
            -- print("[ERROR] Invalid request! " .. reason)
            valid = false
            inner_valid = false
            reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
          else
            params[i] = tmp
          end
        end
        if inner_valid then
          if math.type(params[i]) == "integer" and inputs[i] == "double" then -- convert int to double
            params[i] = params[i] + .0
          elseif math.type(params[i]) == "float" and inputs[i] == "int" then -- convert double to int
            params[i] = math.floor(params[i])
          end
        end
      elseif inputs[i] == "string" then -- string case
        if type(params[i]) ~= "string" and type(params[i]) ~= "number" then
          local reason = string.format("#%i arg of method '%s' must be a valid string, can't convert %s to string...",i,fname,type(params[i]))
          -- print("[ERROR] Invalid request! " .. reason)
          valid = false
          reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
        else
          params[i] = tostring(params[i])
        end
      elseif inputs[i] == "messageStruct" then -- table case
        local reason = ""
        if type(params[i]) ~= "table" then
          reason = string.format("#%i arg of method '%s' must be a table and not %s",i,fname,type(params[i]))
        else
          for k,_ in pairs(params[i]) do
            if k ~= "timeout" and k ~= "fromNode" and k ~= "toNode" and k ~= "type" and k~="value" then
              reason = reason .. string.format("\n\t  #%i arg of method '%s' contains invalid keys! minhaStruct table does not support '%s' key",i,fname,k)
            end
          end

          if tonumber(params[i].timeout) == nil then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'timeout' of type int. Can't convert '%s' to number",i,fname,params[i].timeout)
          else
            params[i].timeout = tonumber(params[i].timeout)
            if math.type(params[i].timeout) ~= swagger_struct.timeout then
              reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'timeout' of type int and not %s",i,fname,type(params[i].timeout))
            end
          end

          if tonumber(params[i].fromNode) == nil then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'fromNode' of type int. Can't convert '%s' to number",i,fname,params[i].node)
          else
            params[i].fromNode = tonumber(params[i].fromNode)
            if math.type(params[i].fromNode) ~= swagger_struct.fromNode then
              reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'fromNode' of type int and not %s",i,fname,type(params[i].node))
            end
          end
          if tonumber(params[i].toNode) == nil then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'toNode' of type int. Can't convert '%s' to number",i,fname,params[i].node)
          else
            params[i].toNode = tonumber(params[i].toNode)
            if math.type(params[i].toNode) ~= swagger_struct.toNode then
              reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'toNode' of type int and not %s",i,fname,type(params[i].node))
            end
          end

          if type(params[i].type) ~= swagger_struct.type then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'type' of type string and not %s",i,fname,type(params[i].type))
          end

          if type(params[i].value) ~= swagger_struct.value then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'value' of type string and not %s",i,fname,type(params[i].value))
          end

        end
        if #reason > 0 then
          -- print("[ERROR] Invalid request! " .. reason)
          valid = false
          reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
        end
      else -- invalid
        local reason = string.format("#%i arg of method '%s' has type %s not supported",i,fname,type(params[i]))
        -- print("[ERROR] Invalid request! " .. reason)
        valid = false
        reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
      end
    end
  end
  return valid, params, reasons
end

return VALIDATOR