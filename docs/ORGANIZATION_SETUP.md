# Organization Setup Guide

## Overview

This guide explains how to set up and manage the organization in your application, especially useful for production environments where the organization needs to be initialized.

## Problem Background

In production, if the organization doesn't exist in the database, accessing `/admin/organization/edit` will result in a 422 error with the message "Request Rejected - The change you requested was rejected. This might be due to invalid data or insufficient permissions."

## Solution

### 1. Make admin_user Association Optional

The `Organization` model has been updated to make the `admin_user` association optional. This allows creating organizations without requiring an admin_user_id:

```ruby
# app/models/organization.rb
belongs_to :admin_user, class_name: 'User', foreign_key: 'admin_user_id', optional: true
```

### 2. Initialize Organization via Rake Task

We provide rake tasks to manage organizations:

#### Initialize Organization (Creates if not exists)

```bash
bundle exec rake organization:init
```

This command will:
- Create an organization if one doesn't exist
- Use default values: name='默认组织', description='系统默认组织'
- Display organization details including invite token

#### Show Organization Details

```bash
bundle exec rake organization:show
```

Displays:
- Organization ID, name, description
- Admin user email (if set)
- Invite token for team members
- Member counts (approved/pending/rejected)

#### Set Admin User for Organization

```bash
bundle exec rake organization:set_admin[user@example.com]
```

Sets the specified user as the organization admin. The user must already exist in the database.

## Production Deployment Steps

When deploying to production for the first time or after database reset:

1. **Deploy the application**
   ```bash
   # Your deployment process
   git push production main
   ```

2. **Run migrations** (if not automatic)
   ```bash
   bundle exec rake db:migrate
   ```

3. **Initialize organization**
   ```bash
   bundle exec rake organization:init
   ```

4. **Verify organization was created**
   ```bash
   bundle exec rake organization:show
   ```

5. **Access admin panel**
   - Navigate to `/admin/organization/edit`
   - Update organization name, description, logo, and background image as needed

6. **(Optional) Set admin user**
   ```bash
   # After creating user accounts
   bundle exec rake organization:set_admin[admin@example.com]
   ```

## Troubleshooting

### 422 Error on /admin/organization/edit

**Symptoms:**
- Error message: "Request Rejected"
- Details: "The change you requested was rejected. This might be due to invalid data or insufficient permissions."

**Causes:**
1. No organization exists in the database
2. Organization association validation failing

**Solution:**
```bash
# Check if organization exists
bundle exec rake organization:show

# If no organization found, initialize it
bundle exec rake organization:init

# Verify it was created
bundle exec rake organization:show
```

### Cannot Update Organization

**Symptoms:**
- Update fails with validation errors
- Form submission returns 422 error

**Solution:**
1. Check validation errors in the form
2. Ensure required fields are filled (name is required)
3. Check file size limits for logo and background_image
4. Verify you're logged in as an admin

### Organization Missing After Database Reset

**Solution:**
Run the initialization task after any database reset:
```bash
bundle exec rake db:reset
bundle exec rake db:seed
bundle exec rake organization:init
```

## Database Schema

The `organizations` table structure:

```ruby
create_table "organizations" do |t|
  t.string "name", null: false          # Required
  t.text "description"                  # Optional
  t.integer "admin_user_id"             # Optional
  t.string "invite_token"               # Auto-generated
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

## API Reference

### Organization Model

**Associations:**
- `belongs_to :admin_user` (optional) - The user who manages the organization
- `has_many :profiles` - Organization members
- `has_one_attached :logo` - Organization logo image
- `has_one_attached :background_image` - Organization background image

**Validations:**
- `name`: Required
- `invite_token`: Must be unique

**Methods:**
- `approved_profiles` - Returns approved members
- `pending_profiles` - Returns pending members
- `rejected_profiles` - Returns rejected members
- `is_admin?(user)` - Check if user is organization admin
- `regenerate_invite_token!` - Generate new invite token
- `invite_url` - Get full invitation URL

### Controller Actions

**Routes:**
- `GET /admin/organization/edit` - Edit organization settings
- `PATCH /admin/organization` - Update organization
- `GET /admin/organization/members` - Member management page
- `POST /admin/organization/members/:profile_id/approve` - Approve member
- `POST /admin/organization/members/:profile_id/reject` - Reject member
- `POST /admin/organization/members/:profile_id/reactivate` - Reactivate member
- `DELETE /admin/organization/members/:profile_id/destroy` - Delete member

## Best Practices

1. **Always initialize organization after database setup**
   - Include in deployment scripts
   - Document in deployment procedures

2. **Set an admin user**
   - Assign an admin user for proper ownership
   - Admin users can manage organization settings

3. **Backup organization data**
   - Include organization table in backups
   - Save uploaded images (logo, background)

4. **Monitor invite token**
   - Regenerate if compromised
   - Keep secure and don't expose publicly

5. **Regular member audits**
   - Review pending members regularly
   - Clean up rejected members periodically

## Related Files

- **Model**: `app/models/organization.rb`
- **Controller**: `app/controllers/admin/organizations_controller.rb`
- **Views**:
  - `app/views/admin/organizations/edit.html.erb`
  - `app/views/admin/organizations/members.html.erb`
- **Rake tasks**: `lib/tasks/organization.rake`
- **Tests**: `spec/requests/admin_organizations_spec.rb`

## Support

If you encounter issues not covered in this guide:
1. Check the application logs for detailed error messages
2. Verify database migrations are up to date
3. Ensure organization record exists in database
4. Contact the development team with error details
