import SettingsContent from '../Wrapper';
import Index from './Index.vue';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/general'),
      component: SettingsContent,
      props: {
        headerTitle: 'GENERAL_SETTINGS.TITLE',
        icon: 'ion-gear-a',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'general_settings_index',
          component: Index,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
