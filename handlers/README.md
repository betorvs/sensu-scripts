
# scripts diversos

## postjson

* postjson.json
* postjson.rb

Baseado no handler do slack para enviar um json para uma url pre definida.



## Remediator

* handler-sensu.rb (sensu.rb is out of date)
* remediator-handler-config.json
* remediator-client.json
* nginx_http_port.json
* remediate-nginx-light.json
* remediate-nginx-heavy.json

Sao exemplos aplicados na versao 0.26 do sensu. Usado para a criacao de uma vacina para um check pre determinado.


## dependencies-filter

Exemplo de filtro de dependencias para inserir nos handlers, retirado de um exemplo de plugin para o flapjack.
https://gist.github.com/hanynowsky/9c700af0913d96ee4c99


## Alerta.io

Veja este fork: https://github.com/betorvs/sensu-alerta

Adicionei o envio do playbook para o alerta.io com as tags html para ao clicar abrir a documentacao.
