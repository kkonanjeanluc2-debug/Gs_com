export class DuplicateError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'DuplicateError';
  }
}

export function handleDatabaseError(error: any): never {
  if (!error) {
    throw new Error('Une erreur inconnue est survenue');
  }

  const errorMessage = error.message || error.toString();

  if (errorMessage.includes('Un produit avec ce nom existe déjà')) {
    throw new DuplicateError('Un produit avec ce nom existe déjà dans votre entreprise');
  }

  if (errorMessage.includes('Un produit avec ce SKU existe déjà')) {
    throw new DuplicateError('Un produit avec ce SKU existe déjà dans votre entreprise');
  }

  if (errorMessage.includes('Un client avec cet email existe déjà')) {
    throw new DuplicateError('Un client avec cet email existe déjà dans votre entreprise');
  }

  if (errorMessage.includes('Un client avec ce numéro de téléphone existe déjà')) {
    throw new DuplicateError('Un client avec ce numéro de téléphone existe déjà dans votre entreprise');
  }

  if (errorMessage.includes('Un fournisseur avec cet email existe déjà')) {
    throw new DuplicateError('Un fournisseur avec cet email existe déjà dans votre entreprise');
  }

  if (errorMessage.includes('Un fournisseur avec ce numéro de téléphone existe déjà')) {
    throw new DuplicateError('Un fournisseur avec ce numéro de téléphone existe déjà dans votre entreprise');
  }

  if (errorMessage.includes('Une catégorie avec ce nom existe déjà')) {
    throw new DuplicateError('Une catégorie avec ce nom existe déjà dans votre entreprise');
  }

  if (errorMessage.includes('Une sous-catégorie avec ce nom existe déjà')) {
    throw new DuplicateError('Une sous-catégorie avec ce nom existe déjà dans cette catégorie');
  }

  if (errorMessage.includes('Une entreprise avec ce nom existe déjà')) {
    throw new DuplicateError('Une entreprise avec ce nom existe déjà');
  }

  if (errorMessage.includes('duplicate key') || errorMessage.includes('unique constraint')) {
    throw new DuplicateError('Cet élément existe déjà. Veuillez utiliser des valeurs différentes.');
  }

  throw new Error(errorMessage);
}
