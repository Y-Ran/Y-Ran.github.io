.PHONY: new_post deploy generate server

new_post:
	hexo new post "post name"

deploy:
	hexo d

generate:
	hexo g

server:
	hexo s
