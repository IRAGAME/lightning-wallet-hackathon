# Contributing to Lightning Wallet

Thanks for your interest!

## How to Contribute

1. Fork the repo
2. Create a feature branch
3. Make changes and commit
4. Push and open a PR

## Development

```bash
# Start PostgreSQL
cd backends/user-backend && docker compose up -d

# Configure env
cp config/.env.lightning.example config/.env.lightning
cp config/.env.user.example config/.env.user
```

## Code Style

- Use ES modules
- Follow existing patterns
- Add JSDoc for functions
- Test with Polar LND simulator
