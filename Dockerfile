# install dependencies
FROM node:18-alpine as base

FROM base as deps
WORKDIR /usr/src/app
COPY package.json yarn.lock ./
RUN apk add --no-cache libc6-compat && \
    yarn install --frozen-lockfile

FROM base as builder
WORKDIR /usr/src/app
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ARG PORT=80
ENV PORT=${PORT}
COPY . .
COPY --from=deps /usr/src/app/node_modules ./node_modules
RUN echo NODE_ENV=${NODE_ENV} && \
    echo PORT=${PORT} && \
    NODE_ENV=${NODE_ENV} yarn build


FROM base as runner
WORKDIR /usr/src/app

ARG PORT=80
ENV PORT=${PORT}
COPY --from=builder /usr/src/app/next.config.js .
COPY --from=builder /usr/src/app/public ./public
COPY --from=builder /usr/src/app/.next/standalone ./
COPY --from=builder /usr/src/app/.next/static ./.next/static
COPY --from=builder /usr/src/app/package.json .
COPY --from=builder /usr/src/app/yarn.lock .

EXPOSE ${PORT}

ENV NEXT_TELEMETRY_DISABLED 1

CMD [ "node", "--max-http-header-size=16000", "server.js" ]