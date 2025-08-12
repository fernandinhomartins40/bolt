import { BaseProviderChecker } from '../base-provider';
import type { StatusCheckResult, ProviderConfig } from '../types';

export class MoonshotStatusChecker extends BaseProviderChecker {
  constructor(config: ProviderConfig) {
    super(config);
  }

  async checkStatus(): Promise<StatusCheckResult> {
    try {
      // Check status page accessibility
      const statusPageResult = await this.checkEndpoint(this.config.statusUrl);
      
      // Check API endpoint
      const apiResult = await this.checkEndpoint(this.config.apiUrl);
      
      const incidents: string[] = [];
      
      if (statusPageResult === 'unreachable') {
        incidents.push('Status page unreachable');
      }
      
      if (apiResult === 'unreachable') {
        incidents.push('API endpoint unreachable');
      } else if (apiResult === 'error') {
        incidents.push('API endpoint returning errors');
      }
      
      // Determine overall status
      let status: 'operational' | 'degraded' | 'down' = 'operational';
      
      if (apiResult === 'unreachable') {
        status = 'down';
      } else if (incidents.length > 0) {
        status = 'degraded';
      }
      
      return {
        status,
        message: status === 'operational' 
          ? 'All systems operational' 
          : `Issues detected: ${incidents.join(', ')}`,
        incidents,
      };
    } catch (error) {
      return {
        status: 'down',
        message: error instanceof Error ? error.message : 'Unknown error',
        incidents: ['Service check failed'],
      };
    }
  }
}