require 'class' -- any class commons enabled library
local lrpc = require 'luarpc'

local p1 = lrpc.createProxy('127.0.0.1', 43196, 'interface.lua')
local p2 = lrpc.createProxy('127.0.0.1', 40854, 'interface.lua')

local r, s = p1.rpc.foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0}, 1)
print('Result for foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0}, 1) request')
print(r)
print(s)
print(' ')

local t, p = p2.rpc.boo(10)
print('Result for boo(10) request')
print(t)
print(p)
print(' ')

print('\n Now showing examples that cause errors... \n')
local r, s = p1.rpc.foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0})
print('Result for foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0}) request')
print(r)
print(s)
print(' ')

local t, p = p2.rpc.boo('matheus')
print('Result for boo("matheus") request')
print(t)
print(p)
print(' ')