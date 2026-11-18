import { triggerOOM, triggerHang } from './article/article.controller';
import { Router } from 'express';
import tagsController from './tag/tag.controller';
import articlesController from './article/article.controller';
import authController from './auth/auth.controller';
import profileController from './profile/profile.controller';
import labController from './lab/lab.controller';

const api = Router()
  .use(tagsController)
  .use(articlesController)
  .use(profileController)
  .use(authController)
  .use(labController)
  .get('/articles/sabotage/oom', triggerOOM)
  .get('/articles/sabotage/hang', triggerHang);

export default Router().use('/api', api);