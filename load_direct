const channel = supabase
  .channel('public:clients')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'clients' }, payload => {
    console.log('Changement détecté:', payload);
  })
  .subscribe();
