.PHONY: new_post deploy generate server clean

new_post:
	hexo new post "如何使用Optional"

deploy:
	hexo clean
	hexo g
	hexo d

server:
	hexo clean
	hexo g
	hexo s

clean:
	hexo clean