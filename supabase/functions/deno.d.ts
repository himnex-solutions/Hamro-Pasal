declare namespace Deno {
  export const env: {
    get(key: string): string | undefined;
  };
}

declare module "https://deno.land/std@0.168.0/http/server.ts" {
  export function serve(handler: (request: Request) => Response | Promise<Response>, options?: any): void;
}

declare module "https://esm.sh/@supabase/supabase-js@2.39.0" {
  export function createClient(supabaseUrl: string, supabaseKey: string, options?: any): any;
  export type SupabaseClient = any;
}

declare module "npm:nodemailer" {
  export function createTransport(options: any): any;
}

declare module "npm:google-auth-library" {
  export class GoogleAuth {
    constructor(options?: any);
    fromJSON(json: any): any;
    getClient(): any;
  }
}
