// Middleware para obtener información del usuario desde el token o headers
// Por ahora, como no tenemos JWT real, usamos headers simples

const getCompanyFilter = (userRole, userCompanyId) => {
  // Super admin ve todo (sin filtro)
  if (userRole === 'super_admin') {
    return null;
  }
  
  // Company admin solo ve datos de su empresa
  if (userRole === 'company_admin' && userCompanyId) {
    return { company_id: userCompanyId };
  }
  
  // Otros roles no tienen acceso administrativo
  return null;
};

// Middleware para agregar filtro de empresa a las queries
const addCompanyFilter = (query, userRole, userCompanyId) => {
  const filter = getCompanyFilter(userRole, userCompanyId);
  
  if (filter && filter.company_id) {
    query = query.eq('company_id', filter.company_id);
  }
  
  return query;
};

module.exports = {
  getCompanyFilter,
  addCompanyFilter,
};

