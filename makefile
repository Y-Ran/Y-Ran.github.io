.PHONY: new_post deploy generate server

new_post:
	hexo new post "post name"

deploy:
	hexo g
	hexo d

server:
	hexo g
	hexo s
