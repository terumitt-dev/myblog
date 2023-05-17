FROM node:16-alpine

WORKDIR /front_end

COPY package.json package-lock.json ./
RUN npm install

ENV PORT=8080

EXPOSE 8080
