import getters from './getters.js'
import mutations from './mutations.js'
import actions from './actions.js'

const state = {
  error: null,
  users: [],
  query: null,
  editID: -1,
};

export default {
  namespaced: true,
  state,
  actions,
  mutations,
  getters
};