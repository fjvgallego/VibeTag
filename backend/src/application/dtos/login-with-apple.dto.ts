export interface LoginWithAppleRequestDTO {
  identityToken: string;
  firstName?: string;
  lastName?: string;
  email?: string;
}

export interface LoginWithAppleResponseDTO {
  user: {
    id: string;
    email: string | null;
    firstName: string | null;
    lastName: string | null;
  };
  token: string;
}
