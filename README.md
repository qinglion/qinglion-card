# ClackyAI Rails7 starter

The template for ClackyAI

## Installation

Install dependencies:

* postgresql

    ```bash
    $ brew install postgresql
    ```

    Ensure you have already initialized a user with username: `postgres` and password: `postgres`( e.g. using `$ createuser -d postgres` command creating one )

* rails 7

    Using `rbenv`, update `ruby` up to 3.x, and install `rails 7.x`

    ```bash
    $ ruby -v ( output should be 3.x )

    $ gem install rails

    $ rails -v ( output should be rails 7.x )
    ```

* npm

    Make sure you have Node.js and npm installed

    ```bash
    $ npm --version ( output should be 8.x or higher )
    ```

Install dependencies, setup db:
```bash
$ ./bin/setup
```

Start it:
```
$ bin/dev
```

## Admin dashboard info

This template already have admin backend for website manager, do not write business logic here.

Access url: /admin

Default superuser: admin

Default password: admin

## Documentation

* [Email Configuration for Private Deployment](docs/EMAIL_CONFIGURATION.md) - 私有化部署邮件服务配置指南
* [Resend Approval Email](docs/RESEND_APPROVAL_EMAIL.md) - 重新发送审核通过邮件功能说明
* [Organization Setup](docs/ORGANIZATION_SETUP.md) - 组织设置说明
* [Registration Flow](docs/REGISTRATION_FLOW.md) - 用户注册流程
* [WeChat Share Setup](docs/WECHAT_SHARE_SETUP.md) - 微信分享配置

## Tech stack

* Ruby on Rails 7.x
* Tailwind CSS 3 (with custom design system)
* Hotwire Turbo (Drive, Frames, Streams)
* Stimulus
* ActionCable
* figaro
* postgres
* active_storage
* kaminari
* puma
* rspec