local MARSHALL = {}

function MARSHALL.unmarshalling(request_params, interface)
  local params = {}
  for _,param in pairs(request_params) do
    value = MARSHALL.convert_param(param, interface)
    table.insert(params,value)
  end
  return params
end

function MARSHALL.convert_param(param, interface)
  local value
  local first_char = param:sub(1,1)
  local tmp_type = type(param)
  if first_char == "'" then --        string
    value = param:sub(2,#param-1) -- exclui '{' e '}' do primeiro e ultimo char da string
  elseif first_char == "{" then --    table
    local str_struct = param:sub(2,#param-1)
    value = MARSHALL.tostruct(str_struct, interface)
  else --                             number
    value = tonumber(param)
    if math.type(value) == "integer" then
      tmp_type = "int"
    else
      tmp_type = "double"
    end
  end
  return value, tmp_type
end

-- Recebe uma string do tipo "'Ana', 20, 50.0" e constroi uma tabela do tipo {nome='Ana', idade=20, peso=50.0} baseada na itnerface do servant stub
function MARSHALL.tostruct(str_struct, interface)
  local tab_struct = {}
  dofile(interface)
  for expression in str_struct:gmatch("([^, ]+)") do -- faz split por ", " e acha expressoes como: nome='Ana'

    local equal_sign = expression:find("=")
    local str_key = expression:sub(1, equal_sign-1)
    local str_value = expression:sub(equal_sign+1, #expression)

    local value, tmp_type = MARSHALL.convert_param(str_value, interface)
    local field_name
    for i=1,#struct.fields do
      if struct.fields[i].name == str_key then
        field_name = struct.fields[i].name
        break
      end
    end
    tab_struct[field_name] = value
  end
  return tab_struct
end

function MARSHALL.create_protocol_msg(fname, params)
  local msg = fname .. "\n" .. MARSHALL.marshalling(params)
  return msg
end

function MARSHALL.marshalling(request_params_table)
  -- local msg = func_name .. "\n"
  local msg = ""
  for i=1,#request_params_table do
    if type(request_params_table[i]) == "table" then
      msg = msg .. "{"
      for k,v in pairs(request_params_table[i]) do
        msg = msg .. k .. "="
        if type(v) == "string" then
          msg = msg .. "'" .. v .. "'"
        else
          msg = msg .. tostring(v)
        end
        msg = msg .. ", "
      end
      if string.sub(msg,#msg-1,#msg) == ", " then
        msg = string.sub(msg,1,#msg-2) .. "}\n"
      end
    elseif type(request_params_table[i]) == "string" then
      msg = msg .. "'" .. request_params_table[i] .. "'" .. "\n"
    else
      msg = msg .. tostring(request_params_table[i]) .. "\n"
    end
  end
  msg = msg .. "-fim-\n" -- end of request
  return msg
end

return MARSHALL