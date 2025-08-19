import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV,
      version: '1.0.0',
    };
  }

  @Get()
  getRoot() {
    return {
      message: 'Chatbot Integration API',
      status: 'running',
      version: '1.0.0',
    };
  }
}
