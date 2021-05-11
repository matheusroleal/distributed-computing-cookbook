local VALIDATOR = {}

-- faz a checagem de tipo para os parametros simples recebidos
local function checkSimpleType(interfaceType, param)
  local err = nil
  if interfaceType == "char" then
    if type(param) ~= "string" or #param ~= 1 then
      err = "Erro parametro não eh char. Param recebido: " .. type(param)
    end
  elseif interfaceType == "string" then
    if type(param) ~= "string" then
      err = "Erro parametro não eh string. Param recebido: " .. type(param)
    end
  elseif interfaceType == "double" then
    if type(param) ~= "number" then
      err = "Erro parametro não eh double. Param recebido: " .. type(param)
    elseif math.type(param) ~= "float" and math.type(param) ~= "integer" then -- aceito int no double
      err = "Erro parametro não eh double. Param recebido: " .. math.type(param)
    end
  elseif interfaceType == "int" then
    if type(param) ~= "number" then
      err = "Erro parametro não eh int. Param recebido: " .. type(param)
    elseif math.type(param) ~= "integer" then
      err = "Erro parametro não eh int. Param recebido: " .. math.type(param)
    end
  else -- tipo desconhecido
    err = "Erro parametro desconhecido. Parametro esperado: " .. interfaceType .. " Param recebido: " .. type(param)
  end
  return err
end

-- checa tipo struct
local function checkStructType(param, structFields)
  local err = nil
  local paramSize = 0
  for k, v in pairs(param) do
    paramSize = paramSize + 1
  end
  if paramSize ~= #structFields then
    return "Erro, o numero de campos da struct está incorreto." .. "num esperado " .. #structFields .. " recebidos " .. paramSize
  end
  for k, v in pairs(structFields) do
    err = checkSimpleType(v.type, param[v.name])
    if err then
      err = "Erro na Struct. No campo " .. v.name .. ". " .. err
      return err
    end
  end
end

-- conta e retorna quantos argumentos são do tipo "in" e quantos do tipo "out"
local function getNumberOfInAndOutArguments(arguments)
  local i = 0
  local o = 0
  for k, v in pairs(arguments) do
    if v.direction == "in" then
      i = i + 1
    else
      o = o + 1
    end
  end
  -- assert(i+o == #arguments) -- sanity check
  return i, o
end

-- checa se os retornos casam com a interface, se o numero de parametros não casar com o esperado, retorna erro direto
-- caso contrario retorna apenas o ultimo erro, se houver
function VALIDATOR.checkReturnTypes(returnTbl, returnType, params, structTbl) -- nao está sendo usado ainda
  local inParams, outParams = getNumberOfInAndOutArguments(params)
  local defaultReturn = 1 -- por default toda funçao retona 1 parametro, vou tratar o caso void passando pra zero
  local expectedReturns = defaultReturn + outParams -- o numero de parametros retornados eh o retorno default da função mais os parametros out
      
  if returnType == "void" then
    defaultReturn = 0
  end -- caso void não tem retorno "default"
  if #returnTbl ~= expectedReturns then
    return "Erro, Numero de retornos diferente do esperado na IDL. Esperava: " .. expectedReturns .. "Recebeu " .. #returnTbl
  end

  local err = nil
  local index = 1
  if defaultReturn == 1 then -- temos que checar o retorno "basico"
    if returnType == structTbl.name then
      err = checkStructType(returnTbl[index], structTbl.fields)
    else
      err = checkSimpleType(returnType, returnTbl[index])
    end
    if err then
      return err
    end
    index = index + 1
  end

  -- checando os parametros out na ordem
  for _, v in ipairs(params) do
    if (v.direction == "out") then
      if v.type == structTbl.name then
        err = checkStructType(returnTbl[index], structTbl.fields)
      else
        err = checkSimpleType(v.type, returnTbl[index])
      end
      if err then
        return err
      end
      index = index + 1
    end
  end
end

-- Checa se todas as funções estão no objeto recebido
-- recebe o objeto representando a interface
function VALIDATOR.checkServantObj(obj, interface) -- Não utilizado para não alterar muito o luarpc que estamos usando
  for k, v in pairs(obj) do
    if interface.methods[k] == nil then
      print("Erro, objeto recebido não implementa a interface a função " .. k .. " não existe")
      return "error"
    end
  end
end

function VALIDATOR.validate_client(params, fname, iface_args, struct_data)
  local valid = true
  local inputs = {}
  local reasons = ""
  for i = 1, #iface_args do
    local arg_direc = iface_args[i].direction
    if arg_direc == "in" or arg_direc == "inout" then
      local arg_type = iface_args[i].type
      table.insert(inputs, arg_type)
    end
  end
if not (#params == #inputs) then
    local reason = string.format("Method '%s' should receive %i args, but received %i instead", fname, #inputs, #params)
    -- -- print("[ERROR] Invalid request! " .. reason)
    valid = false
    reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
    return valid, params, reasons
  end
  for i = 1, #inputs do -- checando tipos, 
    local err
    if inputs[i] == struct_data.name then
      err = checkStructType(params[i], struct_data.fields)
    else
      err = checkSimpleType(inputs[i], params[i])
    end
    if err then
      return false, params, err
    end
  end
  return valid, params, reasons
end

return VALIDATOR