import { BaseProvider, getOpenAILikeModel } from '~/lib/modules/llm/base-provider';
import type { ModelInfo } from '~/lib/modules/llm/types';
import type { IProviderSetting } from '~/types/model';
import type { LanguageModelV1 } from 'ai';

export default class MoonshotProvider extends BaseProvider {
  name = 'Moonshot';
  getApiKeyLink = 'https://platform.moonshot.ai';

  config = {
    baseUrlKey: 'MOONSHOT_API_BASE_URL',
    apiTokenKey: 'MOONSHOT_API_KEY',
  };

  staticModels: ModelInfo[] = [
    {
      name: 'moonshot-v1-8k',
      label: 'Moonshot v1 8K',
      provider: this.name,
      maxTokenAllowed: 8000,
    },
    {
      name: 'moonshot-v1-32k',
      label: 'Moonshot v1 32K',
      provider: this.name,
      maxTokenAllowed: 32000,
    },
    {
      name: 'moonshot-v1-128k',
      label: 'Moonshot v1 128K',
      provider: this.name,
      maxTokenAllowed: 128000,
    },
    {
      name: 'kimi-k2-7b',
      label: 'Kimi K2 7B',
      provider: this.name,
      maxTokenAllowed: 32000,
    },
    {
      name: 'kimi-k2-32b',
      label: 'Kimi K2 32B',
      provider: this.name,
      maxTokenAllowed: 32000,
    },
  ];

  async getDynamicModels(
    apiKeys?: Record<string, string>,
    settings?: IProviderSetting,
    serverEnv: Record<string, string> = {},
  ): Promise<ModelInfo[]> {
    const { baseUrl, apiKey } = this.getProviderBaseUrlAndKey({
      apiKeys,
      providerSettings: settings,
      serverEnv,
      defaultBaseUrlKey: 'MOONSHOT_API_BASE_URL',
      defaultApiTokenKey: 'MOONSHOT_API_KEY',
    });

    if (!baseUrl || !apiKey) {
      return this.staticModels;
    }

    try {
      const response = await fetch(`${baseUrl}/models`, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
        },
      });

      if (!response.ok) {
        console.warn(`Failed to fetch Moonshot models: ${response.statusText}`);
        return this.staticModels;
      }

      const res = (await response.json()) as any;

      if (res.data && Array.isArray(res.data)) {
        const dynamicModels = res.data.map((model: any) => ({
          name: model.id,
          label: model.id,
          provider: this.name,
          maxTokenAllowed: model.context_length || 32000,
        }));

        // Combine static and dynamic models, removing duplicates
        const allModels = [...this.staticModels];
        dynamicModels.forEach((dynamicModel: ModelInfo) => {
          if (!allModels.some(m => m.name === dynamicModel.name)) {
            allModels.push(dynamicModel);
          }
        });

        return allModels;
      }
    } catch (error) {
      console.warn('Error fetching Moonshot models:', error);
    }

    return this.staticModels;
  }

  getModelInstance(options: {
    model: string;
    serverEnv: Env;
    apiKeys?: Record<string, string>;
    providerSettings?: Record<string, IProviderSetting>;
  }): LanguageModelV1 {
    const { model, serverEnv, apiKeys, providerSettings } = options;

    const { baseUrl, apiKey } = this.getProviderBaseUrlAndKey({
      apiKeys,
      providerSettings: providerSettings?.[this.name],
      serverEnv: serverEnv as any,
      defaultBaseUrlKey: 'MOONSHOT_API_BASE_URL',
      defaultApiTokenKey: 'MOONSHOT_API_KEY',
    });

    if (!baseUrl || !apiKey) {
      throw new Error(`Missing configuration for ${this.name} provider. Please set MOONSHOT_API_KEY and optionally MOONSHOT_API_BASE_URL.`);
    }

    return getOpenAILikeModel(baseUrl, apiKey, model);
  }
}