// Jubatus: Online machine learning framework for distributed environment
// Copyright (C) 2011,2012 Preferred Infrastructure and Nippon Telegraph and Telephone Corporation.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

#pragma once

#include <string>
#include <vector>

#include "../common/rpc_util.hpp"
#include "../regression/regression_base.hpp"
#include "../fv_converter/datum_to_fv_converter.hpp"
#include "../storage/storage_base.hpp"
#include "../common/shared_ptr.hpp"
#include "regression_types.hpp"
#include "jubatus_serv.hpp"
#include "diffv.hpp"


namespace jubatus{
namespace server{

struct gresser : public jubatus::framework::mixable<storage::storage_base, diffv>
{
  gresser(){
    function<diffv(const storage::storage_base*)> getdiff(&gresser::get_diff);
    function<int(const storage::storage_base*, const diffv&, diffv&)> reduce(&gresser::reduce);
    function<int(storage::storage_base*, const diffv&)> putdiff(&gresser::put_diff);
    set_mixer(getdiff, reduce, putdiff);
  }
  virtual ~gresser(){}
  static diffv get_diff(const storage::storage_base* model){
    diffv ret;
    ret.count = 1; //FIXME mixer_->get_count();
    model->get_diff(ret.v);
    return ret;
  }
  static int reduce(const storage::storage_base*, const diffv& v, diffv& acc);

  static int put_diff(storage::storage_base* model, const diffv& v){
    diffv diff = v;
    diff /= (double) v.count;
    model->set_average_and_clear_diff(diff.v);
    return 0;
  }

  void clear(){};

  pfi::lang::shared_ptr<regression_base> regression_;
};
  

class regression_serv : public jubatus::framework::jubatus_serv
{
public:
  regression_serv(const framework::server_argv&);
  virtual ~regression_serv();

  static diffv get_diff(const storage::storage_base*);
  static int put_diff(storage::storage_base*, diffv v);
  static int reduce(const storage::storage_base*, const diffv&, diffv&);

  int set_config(config_data);
  config_data get_config();
  int train(std::vector<std::pair<float, datum> > data);
  std::vector<float> estimate(std::vector<datum> data);

  common::cshared_ptr<storage::storage_base> make_model();
  void after_load();

  std::map<std::string, std::map<std::string, std::string> > get_status();
  void check_set_config()const;

private:
  config_data config_;
  pfi::lang::shared_ptr<fv_converter::datum_to_fv_converter> converter_;
  gresser gresser_;
};

void mix_parameter(diffv& lhs, const diffv& rhs);
}
} // namespace jubatus
